/*
 * Copyright (c) 2010-2017 OTClient <https://github.com/edubart/otclient>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#include "uimanager.h"
#include "ui.h"
#include "uiwidget.h"

#include <framework/otml/otml.h>
#include <framework/qml/qmldocument.h>
#include <framework/graphics/graphics.h>
#include <framework/platform/platformwindow.h>
#include <sstream>
#include <map>
#include <framework/core/eventdispatcher.h>
#include <framework/core/application.h>
#include <framework/core/resourcemanager.h>
#include <framework/util/extras.h>

UIManager g_ui;

void UIManager::init()
{
    // creates root widget
    m_rootWidget = std::make_shared<UIWidget>();
    m_rootWidget->setId("root");
    m_mouseReceiver = m_rootWidget;
    m_keyboardReceiver = m_rootWidget;
    m_vars.reserve(100);
}

void UIManager::terminate()
{
    // destroy root widget and its children
    m_rootWidget->destroy();
    m_mouseReceiver = nullptr;
    m_keyboardReceiver = nullptr;
    m_rootWidget = nullptr;
    m_draggingWidget = nullptr;
    m_hoveredWidget = nullptr;
    for(auto& widget : m_pressedWidget)
        widget = nullptr;
    m_styles.clear();
    m_destroyedWidgets.clear();
    m_checkEvent = nullptr;
    m_vars.clear();
    m_hoveredText.clear();
}

void UIManager::render(Fw::DrawPane drawPane)
{
    m_rootWidget->draw(m_rootWidget->getRect(), drawPane);
}

void UIManager::resize(const Size& size)
{
    m_rootWidget->setSize(size);
    m_moveTimer.restart();
}

void UIManager::inputEvent(const InputEvent& event)
{
    UIWidgetList widgetList;
    switch(event.type) {
        case Fw::KeyTextInputEvent:
            g_lua.callGlobalField("g_ui", "onKeyText", event.keyText);
            m_keyboardReceiver->propagateOnKeyText(event.keyText);
            break;
        case Fw::KeyDownInputEvent:
            g_lua.callGlobalField("g_ui", "onKeyDown", event.keyCode, event.keyboardModifiers);
            m_keyboardReceiver->propagateOnKeyDown(event.keyCode, event.keyboardModifiers);
            break;
        case Fw::KeyPressInputEvent:
            g_lua.callGlobalField("g_ui", "onKeyPress", event.keyCode, event.keyboardModifiers, event.autoRepeatTicks);
            m_keyboardReceiver->propagateOnKeyPress(event.keyCode, event.keyboardModifiers, event.autoRepeatTicks);
            break;
        case Fw::KeyUpInputEvent:
            g_lua.callGlobalField("g_ui", "onKeyUp", event.keyCode, event.keyboardModifiers);
            m_keyboardReceiver->propagateOnKeyUp(event.keyCode, event.keyboardModifiers);
            break;
        case Fw::MousePressInputEvent:
            g_lua.callGlobalField("g_ui", "onMousePress", event.mousePos, event.mouseButton);

            if(m_mouseReceiver->isVisible() && (event.mouseButton == Fw::MouseLeftButton || event.mouseButton == Fw::MouseTouch2 || event.mouseButton == Fw::MouseTouch3)) {
                UIWidgetPtr pressedWidget = m_mouseReceiver->recursiveGetChildByPos(event.mousePos, false);
                if(pressedWidget && !pressedWidget->isEnabled())
                    pressedWidget = nullptr;
                updatePressedWidget(event.mouseButton, pressedWidget, event.mousePos);
            }

            m_mouseReceiver->propagateOnMouseEvent(event.mousePos, widgetList);
            for(const UIWidgetPtr& widget : widgetList) {
                widget->recursiveFocus(Fw::MouseFocusReason);
                if(widget->onMousePress(event.mousePos, event.mouseButton))
                    break;
            }

            break;
        case Fw::MouseReleaseInputEvent: {
            g_lua.callGlobalField("g_ui", "onMouseRelease", event.mousePos, event.mouseButton);

            // release dragging widget
            bool accepted = false;
            if(m_draggingWidget && event.mouseButton == Fw::MouseLeftButton)
                accepted = updateDraggingWidget(nullptr, event.mousePos);

            if(!accepted) {
                m_mouseReceiver->propagateOnMouseEvent(event.mousePos, widgetList);

                // mouse release is always fired first on the pressed widget
                if(m_pressedWidget[event.mouseButton]) {
                    auto it = std::find(widgetList.begin(), widgetList.end(), m_pressedWidget[event.mouseButton]);
                    if(it != widgetList.end())
                        widgetList.erase(it);
                    widgetList.push_front(m_pressedWidget[event.mouseButton]);
                }

                for(const UIWidgetPtr& widget : widgetList) {
                    if(widget->onMouseRelease(event.mousePos, event.mouseButton))
                        break;
                }
            }

            if (event.mouseButton == Fw::MouseLeftButton || event.mouseButton == Fw::MouseTouch2 || event.mouseButton == Fw::MouseTouch3) {
                if(m_pressedWidget[event.mouseButton]) {
                    updatePressedWidget(event.mouseButton, nullptr, event.mousePos, !accepted);
                }
            }
            break;
        }
        case Fw::MouseMoveInputEvent: {
            g_lua.callGlobalField("g_ui", "onMouseMove", event.mousePos, event.mouseMoved);

            // start dragging when moving a pressed widget
            if(m_pressedWidget[Fw::MouseLeftButton] && m_pressedWidget[Fw::MouseLeftButton]->isDraggable() && m_draggingWidget != m_pressedWidget[Fw::MouseLeftButton]) {
                // only drags when moving more than 4 pixels
                if((event.mousePos - m_pressedWidget[Fw::MouseLeftButton]->getLastClickPosition()).length() >= 4)
                    updateDraggingWidget(m_pressedWidget[Fw::MouseLeftButton], event.mousePos - event.mouseMoved);
            }

            // mouse move can change hovered widgets
            updateHoveredWidget(true);
            updateHoveredText(true);

            // first fire dragging move
            if(m_draggingWidget) {
                if(m_draggingWidget->onDragMove(event.mousePos, event.mouseMoved))
                    break;
            }

            if (m_pressedWidget[Fw::MouseLeftButton]) {
                if (m_pressedWidget[Fw::MouseLeftButton]->onMouseMove(event.mousePos, event.mouseMoved)) {
                    break;
                }
            }

            //m_mouseReceiver->propagateOnMouseMove(event.mousePos, event.mouseMoved, widgetList);
            m_rootWidget->propagateOnMouseMove(event.mousePos, event.mouseMoved, widgetList);
            for(const UIWidgetPtr& widget : widgetList) {
                if(widget->onMouseMove(event.mousePos, event.mouseMoved))
                    break;
            }
            break;
        }
        case Fw::MouseWheelInputEvent:
            g_lua.callGlobalField("g_ui", "onMouseWheel", event.mousePos, event.wheelDirection);

            m_rootWidget->propagateOnMouseEvent(event.mousePos, widgetList);
            for(const UIWidgetPtr& widget : widgetList) {
                if(widget->onMouseWheel(event.mousePos, event.wheelDirection))
                    break;
            }
            break;
        default:
            break;
    };
}

void UIManager::updatePressedWidget(Fw::MouseButton button, const UIWidgetPtr& newPressedWidget, const Point& clickedPos, bool fireClicks)
{
    UIWidgetPtr oldPressedWidget = m_pressedWidget[button];
    m_pressedWidget[button] = newPressedWidget;

    // when releasing mouse inside pressed widget area send onClick event
    if (fireClicks && oldPressedWidget && oldPressedWidget->isEnabled() && oldPressedWidget->containsPoint(clickedPos))
        oldPressedWidget->onClick(clickedPos);

    if(newPressedWidget)
        newPressedWidget->updateState(Fw::PressedState);

    if(oldPressedWidget)
        oldPressedWidget->updateState(Fw::PressedState);
}

bool UIManager::updateDraggingWidget(const UIWidgetPtr& draggingWidget, const Point& clickedPos)
{
    bool accepted = false;

    UIWidgetPtr oldDraggingWidget = m_draggingWidget;
    m_draggingWidget = nullptr;
    if(oldDraggingWidget) {
        UIWidgetPtr droppedWidget;
        if(!clickedPos.isNull()) {
            auto clickedChildren = m_rootWidget->recursiveGetChildrenByPos(clickedPos);
            for(const UIWidgetPtr& child : clickedChildren) {
                if(child->onDrop(oldDraggingWidget, clickedPos)) {
                    droppedWidget = child;
                    break;
                }
            }
        }

        accepted = oldDraggingWidget->onDragLeave(droppedWidget, clickedPos);
        oldDraggingWidget->updateState(Fw::DraggingState);
    }

    if(draggingWidget) {
        if(draggingWidget->onDragEnter(clickedPos)) {
            m_draggingWidget = draggingWidget;
            draggingWidget->updateState(Fw::DraggingState);
            accepted = true;
        }
    }

    return accepted;
}

void UIManager::updateHoveredWidget(bool now)
{
    if(m_hoverUpdateScheduled && !now)
        return;

    auto func = [this] {
        if(!m_rootWidget)
            return;

        m_hoverUpdateScheduled = false;
        UIWidgetPtr hoveredWidget;
        hoveredWidget = m_rootWidget->recursiveGetChildByPos(g_window.getMousePosition(), false);
        if(hoveredWidget && !hoveredWidget->isEnabled())
            hoveredWidget = nullptr;

        if(hoveredWidget != m_hoveredWidget) {
            UIWidgetPtr oldHovered = m_hoveredWidget;
            m_hoveredWidget = hoveredWidget;
            if(oldHovered) {
                oldHovered->updateState(Fw::HoverState);
                oldHovered->onHoverChange(false);

                if (oldHovered->hasEventListener(EVENT_TEXT_HOVER) && m_hoveredText.length() > 0) {
                    oldHovered->onTextHoverChange(m_hoveredText, false);
                    m_hoveredText.clear();
                }
            }
            if(hoveredWidget) {
                hoveredWidget->updateState(Fw::HoverState);
                hoveredWidget->onHoverChange(true);
            }
        }
    };

    if(now)
        func();
    else {
        m_hoverUpdateScheduled = true;
        g_dispatcher.addEvent(func);
    }
}

void UIManager::updateHoveredText(bool now)
{
    if(m_hoverTextUpdateScheduled && !now || !m_hoveredWidget)
        return;

    auto func = [this] {
        if(!m_rootWidget || !m_hoveredWidget)
            return;

        m_hoverTextUpdateScheduled = false;

        if (m_hoveredWidget->hasEventListener(EVENT_TEXT_HOVER)) {
            std::string hoveredText = m_hoveredWidget->getTextByPos(g_window.getMousePosition());

            if (hoveredText != m_hoveredText) {
                std::string oldHovered = m_hoveredText;
                m_hoveredText = hoveredText;

                if (oldHovered.length() > 0)
                    m_hoveredWidget->onTextHoverChange(oldHovered, false);

                if (m_hoveredText.length() > 0)
                    m_hoveredWidget->onTextHoverChange(m_hoveredText, true);
            }
        }
    };

    if(now)
        func();
    else {
        m_hoverTextUpdateScheduled = true;
        g_dispatcher.addEvent(func);
    }
}

void UIManager::onWidgetAppear(const UIWidgetPtr& widget)
{
    if (widget->containsPoint(g_window.getMousePosition())) {
        updateHoveredWidget();
        updateHoveredText();
    }
}

void UIManager::onWidgetDisappear(const UIWidgetPtr& widget)
{
    if (widget->containsPoint(g_window.getMousePosition())) {
        updateHoveredWidget();
        updateHoveredText();
    }
}

void UIManager::onWidgetDestroy(const UIWidgetPtr& widget)
{
    AutoStat s(STATS_MAIN, "UIManager::onWidgetDestroy", stdext::format("%s (%s)", widget->getId(), widget->getParent() ? widget->getParent()->getId() : ""));

    // release input grabs
    if(m_keyboardReceiver == widget)
        resetKeyboardReceiver();

    if(m_mouseReceiver == widget)
        resetMouseReceiver();

    if (m_hoveredWidget == widget) {
        updateHoveredWidget();
        updateHoveredText();
    }

    for (int i = 0; i <= Fw::MouseButtonLast; ++i) {
        if (m_pressedWidget[i] == widget) {
            updatePressedWidget((Fw::MouseButton)i, nullptr);
        }
    }

    if(m_draggingWidget == widget)
        updateDraggingWidget(nullptr);

    if (!g_extras.debugWidgets)
        return;

    if(widget == m_rootWidget || !m_rootWidget)
        return;

    m_destroyedWidgets.push_back(widget);

    if(m_checkEvent && !m_checkEvent->isExecuted())
        return;

    m_checkEvent = g_dispatcher.scheduleEvent([this] {
        g_lua.collectGarbage();
        UIWidgetList backupList(std::move(m_destroyedWidgets));
        m_destroyedWidgets.clear();
        g_dispatcher.scheduleEvent([backupList] {
            g_lua.collectGarbage();
            for(const UIWidgetPtr& widget : backupList) {
                if(widget.use_count() != 1)
                    g_logger.warning(stdext::format("widget '%s' (parent: '%s' (%s), source: '%s') destroyed but still have %d reference(s) left", widget->getId(), widget->getParent() ? widget->getParent()->getId() : "", widget->getParentId(), widget->getSource(), widget.use_count()-1));
            }
        }, 1);
    }, 1000);
}

void UIManager::clearStyles()
{
    m_styles.clear();
}

bool UIManager::importStyle(std::string file)
{
    try {
        bool isQml = false;
        
        // Check if file is QML
        if (stdext::ends_with(file, ".qml")) {
            isQml = true;
        } else if (!stdext::ends_with(file, ".otui")) {
            // Try to find .qml first, then .otui
            if (g_resources.fileExists(file + ".qml")) {
                file = file + ".qml";
                isQml = true;
            } else {
                file = g_resources.guessFilePath(file, "otui");
            }
        }

        OTMLDocumentPtr doc;
        if (isQml)
            doc = QMLDocument::parse(file);
        else
            doc = OTMLDocument::parse(file);

        if (!doc)
            return false;

        for(const OTMLNodePtr& styleNode : doc->children())
            importStyleFromOTML(styleNode);
        return true;
    } catch(stdext::exception& e) {
        g_logger.error(stdext::format("Failed to import UI styles from '%s': %s", file, e.what()));
        return false;
    }
}

bool UIManager::importStyleFromString(std::string data)
{
    try {
        OTMLDocumentPtr doc = OTMLDocument::parseString(data, g_lua.getCurrentSourcePath());
        for(const OTMLNodePtr& styleNode : doc->children())
            importStyleFromOTML(styleNode);
        return true;
    } catch(stdext::exception& e) {
        g_logger.error(stdext::format("Failed to import UI styles from '%s': %s", g_lua.getCurrentSourcePath(), e.what()));
        return false;
    }
}

void UIManager::importStyleFromOTML(const OTMLNodePtr& styleNode)
{
    std::string tag = styleNode->tag();

    // parse otui variable
    if (stdext::starts_with(tag, "$var-")) {
        std::string var = tag.substr(6);
        addOTUIVar(var, styleNode->rawValue());
        return;
    }

    std::vector<std::string> split = stdext::split(tag, "<");
    if(split.size() != 2)
        throw OTMLException(styleNode, "not a valid style declaration");

    std::string name = split[0];
    std::string base = split[1];
    bool unique = false;

    stdext::trim(name);
    stdext::trim(base);

    if(name[0] == '#') {
        name = name.substr(1);
        unique = true;

        styleNode->setTag(name);
        styleNode->writeAt("__unique", true);
    }

    OTMLNodePtr oldStyle = m_styles[name];

    // Warn about redefined styles
    /*
    if(!g_app.isRunning() && (oldStyle && !oldStyle->valueAt("__unique", false))) {
        auto it = m_styles.find(name);
        if(it != m_styles.end())
            g_logger.warning(stdext::format("style '%s' is being redefined", name));
    }
    */

    if(!oldStyle || !oldStyle->valueAt("__unique", false) || unique) {
        OTMLNodePtr originalStyle = getStyle(base);
        if(!originalStyle)
            stdext::throw_exception(stdext::format("base style '%s', is not defined", base));
        OTMLNodePtr style = originalStyle->clone();
        style->merge(styleNode);
        style->setTag(name);
        m_styles[name] = style;
    }
}

OTMLNodePtr UIManager::getStyle(const std::string& styleName)
{
    auto it = m_styles.find(styleName);
    if(it != m_styles.end())
        return m_styles[styleName];

    // styles starting with UI are automatically defined
    if(stdext::starts_with(styleName, "UI")) {
        OTMLNodePtr node = OTMLNode::create(styleName);
        node->writeAt("__class", styleName);
        m_styles[styleName] = node;
        return node;
    }

    return nullptr;
}

std::string UIManager::getStyleName(const std::string& styleName)
{
    if (const auto& style = getStyle(styleName))
        return style->tag();
    return "";
}

std::string UIManager::getStyleClass(const std::string& styleName)
{
    OTMLNodePtr style = getStyle(styleName);
    if(style && style->get("__class"))
        return style->valueAt("__class");
    return "";
}


UIWidgetPtr UIManager::loadUIFromString(const std::string& data, const UIWidgetPtr& parent)
{
    try {
        std::stringstream sstream;
        sstream.clear(std::ios::goodbit);
        sstream.write(&data[0], data.length());
        sstream.seekg(0, std::ios::beg);
        OTMLDocumentPtr doc = OTMLDocument::parse(sstream, "(string)");
        UIWidgetPtr widget;
        for (const OTMLNodePtr& node : doc->children()) {
            std::string tag = node->tag();

            // import styles in these files too
            if (tag.find("<") != std::string::npos)
                importStyleFromOTML(node);
            else {
                if (widget)
                    stdext::throw_exception("cannot have multiple main widgets in otui files");
                widget = createWidgetFromOTML(node, parent);
            }
        }

        return widget;
    } catch (stdext::exception& e) {
        g_logger.error(stdext::format("failed to load UI from string: %s", e.what()));
        return nullptr;
    }
}

UIWidgetPtr UIManager::loadUI(std::string file, const UIWidgetPtr& parent)
{
    try {
        bool isQml = false;
        
        // Check if file is QML
        if (stdext::ends_with(file, ".qml")) {
            isQml = true;
        } else if (!stdext::ends_with(file, ".otui")) {
            // Try to find .qml first, then .otui
            if (g_resources.fileExists(file + ".qml")) {
                file = file + ".qml";
                isQml = true;
            } else {
                file = g_resources.guessFilePath(file, "otui");
            }
        }

        OTMLDocumentPtr doc;
        if (isQml)
            doc = QMLDocument::parse(file);
        else
            doc = OTMLDocument::parse(file);

        if (!doc)
            return nullptr;

        UIWidgetPtr widget;
        for(const OTMLNodePtr& node : doc->children()) {
            std::string tag = node->tag();
            // parse otui variable
            if (stdext::starts_with(tag, "$var-")) {
                std::string var = tag.substr(6);
                addOTUIVar(var, node->rawValue());
                continue;
            }

            // import styles in these files too
            if(tag.find("<") != std::string::npos)
                importStyleFromOTML(node);
            else {
                if(widget)
                    stdext::throw_exception("cannot have multiple main widgets in otui/qml files");
                widget = createWidgetFromOTML(node, parent);
            }
        }

        return widget;
    } catch(stdext::exception& e) {
        g_logger.error(stdext::format("failed to load UI from '%s': %s", file, e.what()));
        return nullptr;
    }
}

UIWidgetPtr UIManager::loadHtml(std::string file, const UIWidgetPtr& parent)
{
    try {
        // Ensure file has .html extension
        if (!stdext::ends_with(file, ".html")) {
            file = g_resources.guessFilePath(file, "html");
        }

        // Read HTML file content
        std::string htmlContent = g_resources.readFileContents(file);
        if (htmlContent.empty()) {
            g_logger.error(stdext::format("HTML file '%s' is empty or not found", file));
            return nullptr;
        }

        // Parse HTML and create UI widgets
        return parseHtmlContent(htmlContent, parent, file);
    } catch(stdext::exception& e) {
        g_logger.error(stdext::format("failed to load HTML from '%s': %s", file, e.what()));
        return nullptr;
    } catch(...) {
        g_logger.error(stdext::format("Unknown error loading HTML from '%s'", file));
        return nullptr;
    }
}

UIWidgetPtr UIManager::parseHtmlContent(const std::string& htmlContent, const UIWidgetPtr& parent, const std::string& sourceFile)
{
    try {
        // Create root container
        OTMLNodePtr rootNode = OTMLNode::create("UIWidget");
        rootNode->writeAt("id", "htmlContainer");
        rootNode->writeAt("width", 400);
        rootNode->writeAt("height", 300);
        rootNode->writeAt("anchors.top", "parent.top");
        rootNode->writeAt("anchors.left", "parent.left");
        rootNode->writeAt("margin-top", 100);
        rootNode->writeAt("margin-left", 50);
        rootNode->writeAt("background-color", "#2c3e50");  // Dark blue background
        rootNode->writeAt("border-width", 2);
        rootNode->writeAt("border-color", "#ffffff");
        rootNode->writeAt("visible", true);
        rootNode->writeAt("phantom", false);
        rootNode->writeAt("layout", "verticalBox");
        rootNode->writeAt("layout.fit-children", true);
        rootNode->writeAt("padding", 20);
        rootNode->writeAt("spacing", 10);
        
        UIWidgetPtr rootWidget = createWidgetFromOTML(rootNode, parent);
        if (!rootWidget) {
            g_logger.error("Failed to create root HTML widget");
            return nullptr;
        }

        // Make the widget visible and properly positioned
        rootWidget->setVisible(true);
        rootWidget->show();
        rootWidget->raise();

        // Store HTML metadata
        rootWidget->setLuaField("htmlFile", sourceFile);
        rootWidget->setIsHtmlWidget(true);

        // Parse HTML body content
        size_t bodyStart = htmlContent.find("<body");
        size_t bodyEnd = htmlContent.find("</body>");
        
        if (bodyStart != std::string::npos && bodyEnd != std::string::npos) {
            // Find the end of the opening body tag
            size_t bodyContentStart = htmlContent.find(">", bodyStart) + 1;
            std::string bodyContent = htmlContent.substr(bodyContentStart, bodyEnd - bodyContentStart);
            
            parseHtmlElements(bodyContent, rootWidget);
        } else {
            g_logger.warning("No body tags found in HTML content");
        }

        return rootWidget;
    } catch(stdext::exception& e) {
        g_logger.error(stdext::format("failed to parse HTML content: %s", e.what()));
        return nullptr;
    }
}

void UIManager::parseHtmlElements(const std::string& htmlContent, const UIWidgetPtr& parent)
{
    g_logger.info("Starting to parse HTML elements");
    
    // Simple HTML element parser
    size_t pos = 0;
    int elementCount = 0;
    
    while (pos < htmlContent.length()) {
        // Find next HTML tag
        size_t tagStart = htmlContent.find("<", pos);
        if (tagStart == std::string::npos) break;
        
        // Skip closing tags and comments
        if (htmlContent[tagStart + 1] == '/' || htmlContent[tagStart + 1] == '!') {
            pos = htmlContent.find(">", tagStart) + 1;
            continue;
        }
        
        size_t tagEnd = htmlContent.find(">", tagStart);
        if (tagEnd == std::string::npos) break;
        
        std::string tagContent = htmlContent.substr(tagStart + 1, tagEnd - tagStart - 1);
        
        // Parse tag name and attributes
        std::string tagName;
        std::map<std::string, std::string> attributes;
        parseHtmlTag(tagContent, tagName, attributes);
        
        g_logger.info(stdext::format("Found HTML element: %s", tagName));
        
        // Create corresponding UI widget
        UIWidgetPtr widget = createHtmlWidget(tagName, attributes, parent);
        
        if (widget) {
            elementCount++;
            g_logger.info(stdext::format("Created widget for element: %s", tagName));
            
            // Find content between opening and closing tags
            std::string closingTag = "</" + tagName + ">";
            size_t contentStart = tagEnd + 1;
            size_t contentEnd = htmlContent.find(closingTag, contentStart);
            
            if (contentEnd != std::string::npos) {
                std::string elementContent = htmlContent.substr(contentStart, contentEnd - contentStart);
                
                // Handle different element types
                if (tagName == "select") {
                    parseSelectOptions(elementContent, widget);
                } else if (tagName == "div") {
                    // Recursively parse div content
                    parseHtmlElements(elementContent, widget);
                } else if (tagName == "label") {
                    // Set text content for labels
                    stdext::trim(elementContent);
                    if (!elementContent.empty() && elementContent.find("<") == std::string::npos) {
                        widget->setText(elementContent);
                        widget->setTextAlign(Fw::AlignLeft);
                        widget->setColor(Color("#ffffff"));
                        g_logger.info(stdext::format("Set label text: '%s'", elementContent));
                    }
                }
                
                pos = contentEnd + closingTag.length();
            } else {
                pos = tagEnd + 1;
            }
        } else {
            g_logger.warning(stdext::format("Failed to create widget for element: %s", tagName));
            pos = tagEnd + 1;
        }
    }
    
    g_logger.info(stdext::format("Finished parsing HTML elements. Created %d widgets.", elementCount));
}

void UIManager::parseHtmlTag(const std::string& tagContent, std::string& tagName, std::map<std::string, std::string>& attributes)
{
    g_logger.info(stdext::format("Parsing HTML tag: %s", tagContent));
    
    std::istringstream iss(tagContent);
    iss >> tagName;
    
    g_logger.info(stdext::format("Tag name: %s", tagName));
    
    std::string attr;
    while (iss >> attr) {
        size_t equalPos = attr.find("=");
        if (equalPos != std::string::npos) {
            std::string key = attr.substr(0, equalPos);
            std::string value = attr.substr(equalPos + 1);
            
            // Remove quotes
            if (value.length() >= 2 && value.front() == '"' && value.back() == '"') {
                value = value.substr(1, value.length() - 2);
            }
            
            attributes[key] = value;
            g_logger.info(stdext::format("Attribute: %s = %s", key, value));
        }
    }
}

UIWidgetPtr UIManager::createHtmlWidget(const std::string& tagName, const std::map<std::string, std::string>& attributes, const UIWidgetPtr& parent)
{
    g_logger.info(stdext::format("Creating HTML widget for tag: %s", tagName));
    
    OTMLNodePtr node;
    
    if (tagName == "div") {
        node = OTMLNode::create("UIWidget");
        g_logger.info("Creating UIWidget for div");
    } else if (tagName == "label") {
        node = OTMLNode::create("UILabel");
        g_logger.info("Creating UILabel for label");
    } else if (tagName == "select") {
        node = OTMLNode::create("UIComboBox");
        g_logger.info("Creating UIComboBox for select");
    } else {
        // Default to UIWidget for unknown elements
        node = OTMLNode::create("UIWidget");
        g_logger.info(stdext::format("Creating default UIWidget for unknown tag: %s", tagName));
    }
    
    // Set attributes
    for (const auto& attr : attributes) {
        g_logger.info(stdext::format("Processing attribute: %s = %s", attr.first, attr.second));
        
        if (attr.first == "id") {
            node->writeAt("id", attr.second);
            g_logger.info(stdext::format("Set widget ID: %s", attr.second));
        } else if (attr.first == "style") {
            parseStyleAttribute(attr.second, node);
        } else if (attr.first == "onchange") {
            // Store event handler for later binding
            node->writeAt("onchange", attr.second);
        }
    }
    
    // Set default properties based on element type
    if (tagName == "label") {
        node->writeAt("text-auto-resize", true);
        node->writeAt("color", "#ffffff");
        node->writeAt("font", "verdana-11px-antialised");
        node->writeAt("height", 25);
        node->writeAt("width", 200);
        node->writeAt("margin-bottom", 5);
        node->writeAt("text-align", "left");
        node->writeAt("anchors.top", "prev.bottom");
        node->writeAt("anchors.left", "parent.left");
    } else if (tagName == "div") {
        // Set default layout for divs
        node->writeAt("layout", "verticalBox");
        node->writeAt("layout.fit-children", true);
        node->writeAt("padding", 10);
        node->writeAt("spacing", 8);
    } else if (tagName == "select") {
        node->writeAt("width", 200);
        node->writeAt("height", 25);
        node->writeAt("margin-bottom", 10);
        node->writeAt("anchors.top", "prev.bottom");
        node->writeAt("anchors.left", "parent.left");
    }
    
    try {
        UIWidgetPtr widget = createWidgetFromOTML(node, parent);
        
        if (widget) {
            g_logger.info(stdext::format("Successfully created widget for tag: %s", tagName));
            
            // Make widget visible
            widget->setVisible(true);
            widget->show();
            
            // Mark as HTML widget
            widget->setIsHtmlWidget(true);
            
            // Bind event handlers with enhanced event system
            if (attributes.find("onchange") != attributes.end() && tagName == "select") {
                std::string handler = attributes.at("onchange");
                
                // Enhanced event parsing - support for different formats
                size_t colonPos = handler.find(":");
                std::string functionName;
                std::string objectName = "";
                
                if (colonPos != std::string::npos) {
                    // Object method format: "ObjectName:methodName(event)"
                    objectName = handler.substr(0, colonPos);
                    functionName = handler.substr(colonPos + 1);
                } else {
                    // Global function format: "functionName(event)"
                    functionName = handler;
                }
                
                // Remove (event) part and clean up
                size_t parenPos = functionName.find("(");
                if (parenPos != std::string::npos) {
                    functionName = functionName.substr(0, parenPos);
                }
                
                // Store enhanced handler info
                widget->setLuaField("eventHandler", handler);
                widget->setLuaField("eventFunction", functionName);
                widget->setLuaField("eventObject", objectName);
                widget->setLuaField("eventType", "onchange");
                
                g_logger.info(stdext::format("Set enhanced event handler: %s (object: %s)", functionName, objectName));
            }
            
            // Support for other HTML events
            for (const auto& attr : attributes) {
                if (attr.first.substr(0, 2) == "on" && attr.first != "onchange") {
                    // Handle other events like onclick, onmouseover, etc.
                    std::string eventType = attr.first;
                    std::string handler = attr.second;
                    
                    widget->setLuaField("event_" + eventType, handler);
                    g_logger.info(stdext::format("Set HTML event: %s = %s", eventType, handler));
                }
            }
        } else {
            g_logger.error(stdext::format("Failed to create widget from OTML for tag: %s", tagName));
        }
        
        return widget;
    } catch(stdext::exception& e) {
        g_logger.error(stdext::format("failed to create HTML widget '%s': %s", tagName, e.what()));
        return nullptr;
    }
}

void UIManager::parseStyleAttribute(const std::string& style, const OTMLNodePtr& node)
{
    // Parse CSS-like style attribute with enhanced parsing
    std::istringstream iss(style);
    std::string property;
    
    while (std::getline(iss, property, ';')) {
        stdext::trim(property);
        if (property.empty()) continue;
        
        size_t colonPos = property.find(":");
        if (colonPos != std::string::npos) {
            std::string key = property.substr(0, colonPos);
            std::string value = property.substr(colonPos + 1);
            stdext::trim(key);
            stdext::trim(value);
            
            // Convert CSS properties to OTClient properties
            if (key == "width") {
                // Handle different units
                if (value.find("px") != std::string::npos) {
                    node->writeAt("width", stdext::from_string<int>(value.substr(0, value.find("px"))));
                } else if (value.find("%") != std::string::npos) {
                    // Handle percentage (for future implementation)
                    node->writeAt("width", value);
                } else {
                    node->writeAt("width", stdext::from_string<int>(value));
                }
            } else if (key == "height") {
                if (value.find("px") != std::string::npos) {
                    node->writeAt("height", stdext::from_string<int>(value.substr(0, value.find("px"))));
                } else if (value.find("%") != std::string::npos) {
                    node->writeAt("height", value);
                } else {
                    node->writeAt("height", stdext::from_string<int>(value));
                }
            } else if (key == "background-color" || key == "background") {
                node->writeAt("background-color", value);
            } else if (key == "color") {
                node->writeAt("color", value);
            } else if (key == "margin") {
                node->writeAt("margin", stdext::from_string<int>(value.substr(0, value.find("px"))));
            } else if (key == "padding") {
                node->writeAt("padding", stdext::from_string<int>(value.substr(0, value.find("px"))));
            } else if (key == "border-width") {
                node->writeAt("border-width", stdext::from_string<int>(value.substr(0, value.find("px"))));
            } else if (key == "border-color") {
                node->writeAt("border-color", value);
            } else if (key == "font-size") {
                // Map font sizes to OTClient fonts
                if (value.find("px") != std::string::npos) {
                    int size = stdext::from_string<int>(value.substr(0, value.find("px")));
                    if (size <= 11) {
                        node->writeAt("font", "verdana-11px-antialised");
                    } else {
                        node->writeAt("font", "verdana-11px-antialised"); // Default for now
                    }
                }
            } else if (key == "display") {
                if (value == "none") {
                    node->writeAt("visible", false);
                } else {
                    node->writeAt("visible", true);
                }
            } else if (key == "position") {
                // Handle CSS positioning
                if (value == "absolute") {
                    node->writeAt("anchors.top", "parent.top");
                    node->writeAt("anchors.left", "parent.left");
                }
            }
        }
    }
}

void UIManager::parseSelectOptions(const std::string& content, const UIWidgetPtr& selectWidget)
{
    size_t pos = 0;
    
    while (pos < content.length()) {
        size_t optionStart = content.find("<option", pos);
        if (optionStart == std::string::npos) break;
        
        size_t optionTagEnd = content.find(">", optionStart);
        if (optionTagEnd == std::string::npos) break;
        
        size_t optionEnd = content.find("</option>", optionTagEnd);
        if (optionEnd == std::string::npos) break;
        
        // Parse option attributes
        std::string optionTag = content.substr(optionStart + 7, optionTagEnd - optionStart - 7); // Skip "<option"
        std::string optionText = content.substr(optionTagEnd + 1, optionEnd - optionTagEnd - 1);
        stdext::trim(optionText);
        
        // Parse value attribute
        std::string value = optionText; // Default to text content
        size_t valuePos = optionTag.find("value=");
        if (valuePos != std::string::npos) {
            size_t valueStart = optionTag.find("\"", valuePos) + 1;
            size_t valueEnd = optionTag.find("\"", valueStart);
            if (valueStart != std::string::npos && valueEnd != std::string::npos) {
                value = optionTag.substr(valueStart, valueEnd - valueStart);
            }
        }
        
        // Add option to combobox - call the addOption method directly
        selectWidget->callLuaField("addOption", optionText, value);
        
        pos = optionEnd + 9; // Skip "</option>"
    }
}

UIWidgetPtr UIManager::createWidget(const std::string& styleName, const UIWidgetPtr& parent)
{
    OTMLNodePtr node = OTMLNode::create(styleName);
    try {
        return createWidgetFromOTML(node, parent);
    } catch(stdext::exception& e) {
        g_logger.error(stdext::format("failed to create widget from style '%s': %s", styleName, e.what()));
        return nullptr;
    }
}

UIWidgetPtr UIManager::createWidgetFromOTML(const OTMLNodePtr& widgetNode, const UIWidgetPtr& parent)
{
    OTMLNodePtr originalStyleNode = getStyle(widgetNode->tag());
    if(!originalStyleNode)
        stdext::throw_exception(stdext::format("'%s' is not a defined style", widgetNode->tag()));

    OTMLNodePtr styleNode = originalStyleNode->clone();
    styleNode->merge(widgetNode);

    std::string widgetType = styleNode->valueAt("__class");

    // call widget creation from lua
    UIWidgetPtr widget = g_lua.callGlobalField<UIWidgetPtr>(widgetType, "create");
    if(parent)
        parent->addChild(widget);

    if(widget) {
        widget->callLuaField("onCreate");

        widget->setStyleFromNode(styleNode);

        for(const OTMLNodePtr& childNode : styleNode->children()) {
            if(!childNode->isUnique()) {
                createWidgetFromOTML(childNode, widget);
                styleNode->removeChild(childNode);
            }
        }
    } else
        stdext::throw_exception(stdext::format("unable to create widget of type '%s'", widgetType));

    widget->callLuaField("onSetup");

    return widget;
}
