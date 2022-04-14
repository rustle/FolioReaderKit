//
//  Bridge.js
//  FolioReaderKit
//
//  Created by Heberti Almeida on 06/05/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

var thisHighlight;
var audioMarkClass;
var wordsPerMinute = 180;

document.addEventListener("DOMContentLoaded", function(event) {
//    var lnk = document.getElementsByClassName("lnk");
//    for (var i=0; i<lnk.length; i++) {
//        lnk[i].setAttribute("onclick","return callVerseURL(this);");
//    }
    //removeOuterTable()
    //removePSpace()
    //removeBodyClass()
    //reParagraph()
});

// Generate a GUID
function guid() {
    function s4() {
        return Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1);
    }
    var guid = s4() + s4() + '-' + s4() + '-' + s4() + '-' + s4() + '-' + s4() + s4() + s4();
    return guid.toUpperCase();
}

function removePSpace() {
    var ps = Array.from(document.getElementsByTagName('p'));
    var len = ps.length
    var i = 0
    for (; i<len; i++) {
        var p = ps[i]
        p.innerHTML = p.innerHTML.trim()
    }
}

function removeBodyClass() {
    document.body.removeAttribute("class")
}

function reParagraph() {
    var leafNodes = getLeafNodes(document);
    var len = leafNodes.length
    var i = 0
    var startWithSpaceReg = new RegExp('^\\s{2}')
    for (; i<len; i++) {
        var leafNode = leafNodes[i]
        //var lines = leafNode.innerHTML.split(/\r\n|\r|\n/g)
        var lines = leafNode.textContent.split(/\r\n|\r|\n/g)
        var j = 0
        var linesLen = lines.length
        if (linesLen < 10)
            continue
        var para = ""
        var pNodes = []
        for (; j<linesLen; j++) {
            if (lines[j].match(startWithSpaceReg)) {
                if (para.length > 0) {
                    var pNode = document.createElement('p')
                    var text = document.createTextNode(para)
                    pNode.appendChild(text)
                    pNodes.push(pNode)
                }
                para = lines[j]
            } else {
                para = para + lines[j]
            }
        }
        if (para.length > 0) {
            var pNode = document.createElement('p')
            var text = document.createTextNode(para)
            pNode.appendChild(text)
            pNodes.push(pNode)
        }
        if (pNodes.length > 0) {
            //alert(leafNode.textContent.split(/\r\n|\r|\n/g).length)
            //alert(pNodes.length)
            //leafNode.innerHTML = ""
            leafNode.removeChild(leafNode.firstChild)
            var k = 0
            var pNodesLen = pNodes.length
            for(; k<pNodesLen; k++) {
                leafNode.appendChild(pNodes[k])
            }
        }
    }
}

function getLeafNodes(master) {
    var nodes = Array.prototype.slice.call(master.getElementsByTagName("*"), 0);
    var leafNodes = nodes.filter(function(elem) {
        if (elem.hasChildNodes()) {
            // see if any of the child nodes are elements
            for (var i = 0; i < elem.childNodes.length; i++) {
                if (elem.childNodes[i].nodeType == 1) {
                    // there is a child element, so return false to not include
                    // this parent element
                    return false;
                }
            }
        }
        return true;
    });
    return leafNodes;
}
/**
 * Get an array containing the text nodes within a DOM node.
 *
 * From http://stackoverflow.com/a/4399718/843621
 *
 * For example get all text nodes from <body>
 *
 * var body = document.getElementsByTagName('body')[0];
 *
 * getTextNodesIn(body);
 *
 * @param node Any DOM node.
 * @param [includeWhitespaceNodes=false] Whether to include whitespace-only nodes.
 * @return An array containing TextNodes.
 */

function getTextNodesIn(node, includeWhitespaceNodes) {
    var textNodes = [], whitespace = /^\s*$/;

    function getTextNodes(node) {
        if (node.nodeType == 3) {
            if (includeWhitespaceNodes || !whitespace.test(node.nodeValue)) {
                textNodes.push(node);
            }
        } else {
            for (var i = 0, len = node.childNodes.length; i < len; ++i) {
                getTextNodes(node.childNodes[i]);
            }
        }
    }

    getTextNodes(node);
    return textNodes;
}

function removeOuterTable() {
    // table references the table DOM element
    var tables = Array.from(document.getElementsByTagName('table'));
    var handled = 0;
    while (tables.length > 0) {
        var table = tables[0];
        //alert(table.innerHTML);
//        if (!table.hasAttribute("width")) {
//            break
//        }
        var keep = document.createDocumentFragment(),
        tds = table.getElementsByTagName('td'),
        td, i, l;

        // alert("after keep");
        
        while (tds.length > 0) {
            //alert(i + " in " + tds.length)
            td = tds[0];
            //alert(td.innerHTML)
            while(td.firstChild) {
                var pArray = Array.from(td.getElementsByTagName('p'))
                if (pArray.length == 0 && td.firstChild.textContent.length > 1) {
                    var pNode = document.createElement('p')
                    pNode.appendChild(td.firstChild)
                    keep.appendChild(pNode)
                    //alert(pNode.innerHTML)
                } else if (td.firstChild.tagName != "BR") {
                    //alert(td.firstChild.tagName)
                    keep.appendChild(td.firstChild);
                } else {
                    td.removeChild(td.firstChild)
                }
            }
            //alert("after while(td.firstChild)")
            
            td.parentNode.removeChild(td)
            tds = table.getElementsByTagName('td')
        }
        
        var tableParent = table.parentNode
        tableParent.insertBefore(keep, table);
        tableParent.removeChild(table);
        
        // alert(tableParent.innerHTML)
        
        tables = Array.from(document.getElementsByTagName('table'));
        //alert(tables.length);
    }
    return handled
}

function tweakStyleOnly() {
    var tables = [...document.getElementsByTagName('table')]
    tables.forEach( (table) => {
        table.removeAttribute("width")
        table.removeAttribute("class")
        table.setAttribute("border", "0")
    } )
    var tds = [...document.getElementsByTagName('td')]
    tds.forEach((item) => {
        item.removeAttribute("class")
    })
}

function injectHighlight(highlightJSONDataEncoded) {    //sample data
//    var cfiStart = "/2/4/2/2/2/2/4/2/8/2/1:20";
//    var cfiEnd = "/2/4/2/2/2/2/4/2/8/2/1:41";
//    var cfiStart = "epubcfi(/10/2/4/2/2/2/2/4/2/8/2/1:20)"
//    var cfiEnd   = "epubcfi(/10/2/4/2/2/2/2/4/2/8/2/1:42)"
    
    var sHighlightJson = window.atob(highlightJSONDataEncoded);
    var oHighlight = JSON.parse(sHighlightJson);
    oHighlight.content = decodeURIComponent(oHighlight.contentEncoded)
    oHighlight.contentPost = decodeURIComponent(oHighlight.contentPostEncoded)
    oHighlight.contentPre = decodeURIComponent(oHighlight.contentPreEncoded)

    window.webkit.messageHandlers.FolioReaderPage.postMessage("injectHighlight oHighlight " + JSON.stringify(oHighlight))
    
    var cfiStart = "epubcfi(" + oHighlight.cfiStart + ")"
    var startNode = window.EPUBcfi.getTargetElementWithPartialCFI(encodeURI(cfiStart), document, [], ["highlight"], []).get(0)
    var startTextInfo = window.EPUBcfi.getTextTerminusInfoWithPartialCFI(encodeURI(cfiStart), document, [], ["highlight"], [])
    var startTextInfoOffset = startTextInfo.textOffset
    
    window.webkit.messageHandlers.FolioReaderPage.postMessage("injectHighlight startNode " + startNode + " " + startNode.textContent)
    window.webkit.messageHandlers.FolioReaderPage.postMessage("injectHighlight startTextInfo " + startTextInfo + " " + JSON.stringify(startTextInfo))
    window.webkit.messageHandlers.FolioReaderPage.postMessage("injectHighlight startTextInfo " + startTextInfo.textNode.textContent)

    var cfiEnd   = "epubcfi(" + oHighlight.cfiEnd + ")"
    var endNode   = window.EPUBcfi.getTargetElementWithPartialCFI(encodeURI(cfiEnd),   document, [], ["highlight"], []).get(0)
    var endTextInfo = window.EPUBcfi.getTextTerminusInfoWithPartialCFI(encodeURI(cfiEnd), document, [], ["highlight"], [])
    var endTextInfoOffset = endTextInfo.textOffset
    window.webkit.messageHandlers.FolioReaderPage.postMessage("injectHighlight endNode " + endNode + " " + endNode.textContent)
    window.webkit.messageHandlers.FolioReaderPage.postMessage("injectHighlight endTextInfo " + endTextInfo + " " + JSON.stringify(endTextInfo))
    window.webkit.messageHandlers.FolioReaderPage.postMessage("injectHighlight endTextInfo " + endTextInfo.textNode.textContent)
    
    var curTextLengthUptoStartNode = 0    //for locating actual startNode
    while (curTextLengthUptoStartNode + startNode.textContent.length < startTextInfoOffset) {
        curTextLengthUptoStartNode += startNode.textContent.length
        startNode = startNode.nextSibling
        if (startNode == null)
            break
    }
    if (startNode == null) {
        return "startOffset exceeding content length"
    }
    window.webkit.messageHandlers.FolioReaderPage.postMessage("injectHighlight startNodeNew " + startNode + " " + startNode.textContent)
    
    var curTextLengthUptoEndNode = 0    //for locating actual endNode
    while (curTextLengthUptoEndNode + endNode.textContent.length < endTextInfoOffset) {
        curTextLengthUptoEndNode += endNode.textContent.length
        endNode = endNode.nextSibling
        if (endNode == null)
            break;
    }
    if (endNode == null) {
        return "endOffset exceeding content length"
    }
    window.webkit.messageHandlers.FolioReaderPage.postMessage("injectHighlight endNodeNew " + endNode + " " + endNode.textContent)
    
    var range = document.createRange()
    range.setStart(startNode, startTextInfoOffset - curTextLengthUptoStartNode)
    range.setEnd(endNode, endTextInfoOffset - curTextLengthUptoEndNode)
    window.webkit.messageHandlers.FolioReaderPage.postMessage("injectHighlight range " + range)

    // check highlight overlapping
    const highlightItems = [...document.getElementsByTagName("highlight")];
    for (i=0; i<highlightItems.length; i++) {
        if (range.intersectsNode(highlightItems[i])) {
            return "Overlapping highlights are not supported"
        }
    }
//    var overlapping = false
//    highlightItems.forEach((item) => {
//        window.webkit.messageHandlers.FolioReaderPage.postMessage("injectHighlight highlightItem " + item.outerHTML)
//        var textNodes = getTextNodesIn(item)
//        for (i=0; i<textNodes.length; i++) {
//            overlapping = overlapping || range.intersectsNode(textNodes[i])
//        }
//    });
//    if (overlapping) {
//        return "Overlapping highlights are not supported"
//    }
    if (startNode != endNode) {
        var ancestor = range.commonAncestorContainer
        var textNodes = getTextNodesIn(ancestor)
        window.webkit.messageHandlers.FolioReaderPage.postMessage("injectHighlight ancestor " + ancestor.textContent)

        var id_seq = 0
        for (i=0; i<textNodes.length; i++) {
            var intersects = range.intersectsNode(textNodes[i])
            window.webkit.messageHandlers.FolioReaderPage.postMessage("injectHighlight compareMask " + intersects + " " + textNodes[i].textContent)
            if (intersects) {
                var subrange = document.createRange()
                if (textNodes[i] == startNode) {
                    subrange.setStart(startNode, startTextInfoOffset - curTextLengthUptoStartNode)
                    subrange.setEnd(startNode, startNode.textContent.length)
                } else if (textNodes[i] == endNode) {
                    subrange.setStart(endNode, 0)
                    subrange.setEnd(endNode, endTextInfoOffset - curTextLengthUptoEndNode)
                } else {
                    subrange.setStart(textNodes[i], 0)
                    subrange.setEnd(textNodes[i], textNodes[i].textContent.length)
                }
                var selectionContents = subrange.extractContents();
                var elm = document.createElement("highlight");
                var id = oHighlight.highlightId
                
                elm.appendChild(selectionContents);
                elm.setAttribute("id", id + "." + id_seq.toString());
                elm.setAttribute("onclick","callHighlightURL(this);");
                elm.setAttribute("class", oHighlight.style);
                
                subrange.insertNode(elm);
                window.webkit.messageHandlers.FolioReaderPage.postMessage("injectHighlight subrange " + subrange + " " + elm)
                id_seq ++
            }
        }
    } else {
        var selectionContents = range.extractContents();
        var elm = document.createElement("highlight");
        var id = oHighlight.highlightId
        
        elm.appendChild(selectionContents);
        elm.setAttribute("id", id);
        elm.setAttribute("onclick","callHighlightURL(this);");
        elm.setAttribute("class", oHighlight.style);
        
        range.insertNode(elm);
        window.webkit.messageHandlers.FolioReaderPage.postMessage("injectHighlight finished " + range + " " + elm)
    }
    window.webkit.messageHandlers.FolioReaderPage.postMessage("injectHighlight getHTML " + getHTML());
}
// Get All HTML
function getHTML() {
    return document.documentElement.outerHTML;
}

// Class manipulation
function hasClass(ele,cls) {
  return !!ele.className.match(new RegExp('(\\s|^)'+cls+'(\\s|$)'));
}

function addClass(ele,cls) {
  if (!hasClass(ele,cls)) ele.className += " "+cls;
}

function removeClass(ele,cls) {
  if (hasClass(ele,cls)) {
    var reg = new RegExp('(\\s|^)'+cls+'(\\s|$)');
    ele.className=ele.className.replace(reg,' ');
  }
}

// Font name class
function setFontName(cls) {
    var elm = document.documentElement;
    removeClass(elm, "andada");
    removeClass(elm, "lato");
    removeClass(elm, "lora");
    removeClass(elm, "raleway");
    addClass(elm, cls);
}

// Toggle night mode
function nightMode(enable) {
    var elm = document.documentElement;
    if(enable) {
        addClass(elm, "nightMode");
    } else {
        removeClass(elm, "nightMode");
    }
}

// Toggle night mode
function themeMode(mode) {
    var elm = document.documentElement;
    removeClass(elm, "nightMode");
    removeClass(elm, "serpiaMode");
    removeClass(elm, "greenMode");
    removeClass(elm, "darkMode");
    if( mode == 1) {
        addClass(elm, "serpiaMode");
    }
    if( mode == 2) {
        addClass(elm, "greenMode");
    }
    if( mode == 3) {
        addClass(elm, "darkMode");
    }
    if( mode == 4) {
        addClass(elm, "nightMode");
    }
}

// Set font size
function setFontSize(cls) {
    var elm = document.documentElement;
    removeClass(elm, "textSizeOne");
    removeClass(elm, "textSizeTwo");
    removeClass(elm, "textSizeThree");
    removeClass(elm, "textSizeFour");
    removeClass(elm, "textSizeFive");
    addClass(elm, cls);
}

/*
 *	Native bridge Highlight text
 */
function highlightString(style) {
    var range = window.getSelection().getRangeAt(0);
    var startOffset = range.startOffset;
    var endOffset = range.endOffset;
    var selectionContents = range.extractContents();
    var elm = document.createElement("highlight");
    var id = guid();
    
    elm.appendChild(selectionContents);
    elm.setAttribute("id", id);
    elm.setAttribute("onclick","callHighlightURL(this);");
    elm.setAttribute("class", style);
    
    range.insertNode(elm);
    thisHighlight = elm;
    
    var params = [];
    params.push({id: id, rect: getRectForSelectedText(elm), startOffset: startOffset.toString(), endOffset: endOffset.toString()});
    
    return JSON.stringify(params);
}

function highlightStringCFI(style) {
    var range = window.getSelection().getRangeAt(0);
    var startOffset = range.startOffset;
    var endOffset = range.endOffset;

    var startContainer = range.startContainer
    var startContainerText = startContainer.textContent
    
    var endContainer = range.endContainer
    var endContainerText = endContainer.textContent
    
    window.webkit.messageHandlers.FolioReaderPage.postMessage("highlightStringCFI startContainerText " + startContainerText);
    window.webkit.messageHandlers.FolioReaderPage.postMessage("highlightStringCFI endContainerText " + endContainerText);

    //Text Location Assertion
    var precedingStartOffset = startOffset - 20
    if (precedingStartOffset < 0) {
        precedingStartOffset = 0
    }
    var precedingText = startContainerText.substring(precedingStartOffset, startOffset)
    
    var followingEndOffset = endOffset + 20
    if (followingEndOffset > endContainerText.length) {
        followingEndOffset = endContainerText.length
    }
    var followingText = endContainerText.substring(endOffset, followingEndOffset)
    
    window.webkit.messageHandlers.FolioReaderPage.postMessage("highlightStringCFI precedingText " + precedingText);
    window.webkit.messageHandlers.FolioReaderPage.postMessage("highlightStringCFI followingText " + followingText);

    var tmpNode = startContainer.previousSibling
    var prevHighlightLengthStart = 0
    while (tmpNode != null) {
        window.webkit.messageHandlers.FolioReaderPage.postMessage("highlightStringCFI tmpNodeName " + tmpNode.nodeName);

        if (tmpNode.nodeName == "HIGHLIGHT") {
            prevHighlightLengthStart += tmpNode.textContent.length
        } else if (tmpNode.nodeName != "#text") {
            break
        }
        tmpNode = tmpNode.previousSibling
    }
    window.webkit.messageHandlers.FolioReaderPage.postMessage("highlightStringCFI prevHighlightLengthStart " + prevHighlightLengthStart);

    var tmpNode = endContainer.previousSibling
    var prevHighlightLengthEnd = 0
    while (tmpNode != null) {
        window.webkit.messageHandlers.FolioReaderPage.postMessage("highlightStringCFI tmpNodeName " + tmpNode.nodeName);

        if (tmpNode.nodeName == "HIGHLIGHT") {
            prevHighlightLengthEnd += tmpNode.textContent.length
        } else if (tmpNode.nodeName != "#text") {
            break
        }
        tmpNode = tmpNode.previousSibling
    }
    window.webkit.messageHandlers.FolioReaderPage.postMessage("highlightStringCFI prevHighlightLengthEnd " + prevHighlightLengthEnd);
    
    var cfiStart = window.EPUBcfi.generateCharacterOffsetCFIComponent(
                        startContainer,startOffset,[],["highlight"],[])
    var cfiEnd = window.EPUBcfi.generateCharacterOffsetCFIComponent(
                        endContainer,endOffset,[],["highlight"],[])
    
    var params = [];
    params.push({
        id: guid(),
        startOffset: startOffset.toString(),
        endOffset: endOffset.toString(),
        content: range.cloneContents().textContent,
        contentPre: precedingText,
        contentPost: followingText,
        cfiStart: cfiStart,
        cfiEnd: cfiEnd,
        prevHighlightLengthStart: prevHighlightLengthStart.toString(),
        prevHighlightLengthEnd: prevHighlightLengthEnd.toString()
    });
    
    return JSON.stringify(params);
}

function highlightStringWithNoteCFI(style) {
    var range = window.getSelection().getRangeAt(0);
    var startOffset = range.startOffset;
    var endOffset = range.endOffset;

    var startContainer = range.startContainer
    var startContainerText = startContainer.textContent
    
    var endContainer = range.endContainer
    var endContainerText = endContainer.textContent
    
    window.webkit.messageHandlers.FolioReaderPage.postMessage("highlightStringCFI startContainerText " + startContainerText);
    window.webkit.messageHandlers.FolioReaderPage.postMessage("highlightStringCFI endContainerText " + endContainerText);

    //Text Location Assertion
    var precedingStartOffset = startOffset - 20
    if (precedingStartOffset < 0) {
        precedingStartOffset = 0
    }
    var precedingText = startContainerText.substring(precedingStartOffset, startOffset)
    
    var followingEndOffset = endOffset + 20
    if (followingEndOffset > endContainerText.length) {
        followingEndOffset = endContainerText.length
    }
    var followingText = endContainerText.substring(endOffset, followingEndOffset)
    
    window.webkit.messageHandlers.FolioReaderPage.postMessage("highlightStringCFI precedingText " + precedingText);
    window.webkit.messageHandlers.FolioReaderPage.postMessage("highlightStringCFI followingText " + followingText);

    var cfiStart = window.EPUBcfi.generateCharacterOffsetCFIComponent(startContainer,startOffset,[],["highlight"],[])
    var cfiEnd = window.EPUBcfi.generateCharacterOffsetCFIComponent(endContainer,endOffset,[],["highlight"],[])
    
    var selectionContents = range.extractContents();
    var elm = document.createElement("highlight");
    var id = guid();
    
    elm.appendChild(selectionContents);
    elm.setAttribute("id", id);
    elm.setAttribute("onclick","callHighlightWithNoteURL(this);");
    elm.setAttribute("class", style);
    
    range.insertNode(elm);
    thisHighlight = elm;
    
    var params = [];
    params.push({
        id: id,
        rect: getRectForSelectedText(elm),
        startOffset: startOffset.toString(),
        endOffset: endOffset.toString(),
        content: elm.textContent,
        contentPre: precedingText,
        contentPost: followingText,
        cfiStart: cfiStart,
        cfiEnd: cfiEnd
    });
    
    return JSON.stringify(params);
}

function highlightStringWithNote(style) {
    var range = window.getSelection().getRangeAt(0);
    var startOffset = range.startOffset;
    var endOffset = range.endOffset;
    var selectionContents = range.extractContents();
    var elm = document.createElement("highlight");
    var id = guid();
    
    elm.appendChild(selectionContents);
    elm.setAttribute("id", id);
    elm.setAttribute("onclick","callHighlightWithNoteURL(this);");
    elm.setAttribute("class", style);
    
    range.insertNode(elm);
    thisHighlight = elm;
    
    var params = [];
    params.push({id: id, rect: getRectForSelectedText(elm), startOffset: startOffset.toString(), endOffset: endOffset.toString()});
    
    return JSON.stringify(params);
}

function getHighlightId() {
    var id = thisHighlight.id
    var indexOfDot = id.indexOf(".")
    if (indexOfDot > 0) {
        id = id.substring(0, indexOfDot)
    }
    return id;
}

// Menu colors
function setHighlightStyle(style) {
    var id = thisHighlight.id
    var indexOfDot = id.indexOf(".")
    if (indexOfDot == -1) {
        thisHighlight.className = style;
    } else {
        id = id.substring(0, indexOfDot)
        const highlightItems = document.querySelectorAll('[id^="' + id + '."]');
        highlightItems.forEach(function(item) {
          item.className = style;
        });
    }
    
    return id;
}

function removeThisHighlight() {
    var id = thisHighlight.id
    var indexOfDot = id.indexOf(".")
    if (indexOfDot == -1) {
        thisHighlight.outerHTML = thisHighlight.innerHTML;
    } else {
        id = id.substring(0, indexOfDot)
        removeHighlightById(id)
    }
    return id
}

function removeHighlightById(elmId) {
    var elm = document.getElementById(elmId);
    if (elm != null) {
        elm.outerHTML = elm.innerHTML;
    } else {
        const highlightItems = document.querySelectorAll('[id^="' + elmId + '."]');
        highlightItems.forEach(function(item) {
          item.outerHTML = item.innerHTML;
        });
    }
    return elmId
}

function getHighlightContent() {
    var id = thisHighlight.id
    var indexOfDot = id.indexOf(".")
    if (indexOfDot == -1) {
        return thisHighlight.textContent
    } else {
        id = id.substring(0, indexOfDot)
        var text = ""
        const highlightItems = document.querySelectorAll('[id^="' + id + '."]');
        highlightItems.forEach(function(item) {
          text += item.textContent
        });
        return text
    }
}

function getBodyText() {
    return document.body.innerText;
}

// Method that returns only selected text plain
var getSelectedText = function() {
    var selObj = window.getSelection()
    var selRange = selObj.getRangeAt(0)
    var selContainer = selRange.startContainer
    window.webkit.messageHandlers.FolioReaderPage.postMessage("Selection Container " + selContainer.outerHTML)

    return selObj.toString();
}

// Method that gets the Rect of current selected text
// and returns in a JSON format
var getRectForSelectedText = function(elm) {
    if (typeof elm === "undefined") elm = window.getSelection().getRangeAt(0);
    
    var rect = elm.getBoundingClientRect();
    return "{{" + rect.left + "," + rect.top + "}, {" + rect.width + "," + rect.height + "}}";
}

// Method that call that a hightlight was clicked
// with URL scheme and rect informations
var callHighlightURL = function(elm) {
	event.stopPropagation();
	var URLBase = "highlight://";
    var currentHighlightRect = getRectForSelectedText(elm);
    thisHighlight = elm;
    
    window.location = URLBase + encodeURIComponent(currentHighlightRect);
}

// Method that call that a hightlight with note was clicked
// with URL scheme and rect informations
var callHighlightWithNoteURL = function(elm) {
    event.stopPropagation();
    var URLBase = "highlight-with-note://";
    var currentHighlightRect = getRectForSelectedText(elm);
    thisHighlight = elm;
    
    window.location = URLBase + encodeURIComponent(currentHighlightRect);
}

// Reading time
function getReadingTime() {
    var text = document.body.innerText;
    var totalWords = text.trim().split(/\s+/g).length;
    var wordsPerSecond = wordsPerMinute / 60; //define words per second based on words per minute
    var totalReadingTimeSeconds = totalWords / wordsPerSecond; //define total reading time in seconds
    var readingTimeMinutes = Math.round(totalReadingTimeSeconds / 60);

    return readingTimeMinutes;
}

/**
 Get Vertical or Horizontal paged #anchor offset
 */
var getAnchorOffset = function(target, horizontal) {
    var elem = document.getElementById(target);
    
    if (!elem) {
        elem = document.getElementsByName(target)[0];
    }
    
    if (horizontal) {
        return document.body.clientWidth * Math.floor(elem.offsetTop / window.innerHeight);
    }
    
    return elem.offsetTop;
}

var getClickAnchorOffset = function(target) {
    var elems = document.getElementsByTagName("a");
    
    var elem;
    for (var i=0; i<elems.length; i++) {
        var rect = elems[i].getBoundingClientRect();
        var visible = (rect.top >= 0 && rect.left >= 0 &&
            rect.bottom <= (window.innerHeight || document.documentElement.clientHeight) && /* or $(window).height() */
            rect.right <= (window.innerWidth || document.documentElement.clientWidth) /* or $(window).width() */);
        window.webkit.messageHandlers.FolioReaderPage.postMessage("getClickAnchorOffset for " + elems[i].innerText + " " + rect);

        if (!visible) {
            continue
        }
        var href = elems[i].getAttribute("href");
        if (href && href.endsWith("#" + target)) {
            return rect.top;
        }
    }
    
    return ""
}

function highlightAnchorText(target, highlightStyle, seconds) {
    var elem = document.getElementById(target);
    
    if (!elem) {
        elem = document.getElementsByName(target)[0];
    }
    
    while ( elem && elem.innerText.length <= 5 && elem.parentNode && elem.parentNode.childElementCount <= 5 ) {
        elem = elem.parentNode
    }
    while ( elem && elem.innerText.length <= 5 && elem.nextElementSibling ) {
        elem = elem.nextElementSibling
    }
    if (!elem) {
        return
    }
    
    addClass(elem, highlightStyle)
    var t = setTimeout(function(){
        removeClass(elem, highlightStyle)
    },(seconds*1000));
//    var origcolor = elem.style.backgroundColor
//    elem.style.backgroundColor = color;
//    var t = setTimeout(function(){
//        elem.style.backgroundColor = origcolor;
//    },(seconds*1000));
    
//    var rule = "p { background-color: "+color+" !important; }"
//    var stylesheet = document.styleSheets[document.styleSheets.length-1];
//    stylesheet.insertRule(rule)
    
    window.webkit.messageHandlers.FolioReaderPage.postMessage("highlightAnchorText finished for " + elem.tagName + " " + elem.className);

}

function findElementWithID(node) {
    if( !node || node.tagName == "BODY")
        return null
    else if( node.id )
        return node
    else
        return findElementWithID(node)
}

function findElementWithIDInView() {

    if(audioMarkClass) {
        // attempt to find an existing "audio mark"
        var el = document.querySelector("."+audioMarkClass)

        // if that existing audio mark exists and is in view, use it
        if( el && el.offsetTop > document.body.scrollTop && el.offsetTop < (window.innerHeight + document.body.scrollTop))
            return el
    }

    // @NOTE: is `span` too limiting?
    var els = document.querySelectorAll("span[id]")

    for(indx in els) {
        var element = els[indx];

        // Horizontal scroll
        if (document.body.scrollTop == 0) {
            var elLeft = document.body.clientWidth * Math.floor(element.offsetTop / window.innerHeight);
            // document.body.scrollLeft = elLeft;

            if (elLeft == document.body.scrollLeft) {
                return element;
            }

        // Vertical
        } else if(element.offsetTop > document.body.scrollTop) {
            return element;
        }
    }

    return null
}


/**
 Play Audio - called by native UIMenuController when a user selects a bit of text and presses "play"
 */
function playAudio() {
    var sel = getSelection();
    var node = null;

    // user selected text? start playing from the selected node
    if (sel.toString() != "") {
        node = sel.anchorNode ? findElementWithID(sel.anchorNode.parentNode) : null;

    // find the first ID'd element that is within view (it will
    } else {
        node = findElementWithIDInView()
    }

    playAudioFragmentID(node ? node.id : null)
}


/**
 Play Audio Fragment ID - tells page controller to begin playing audio from the following ID
 */
function playAudioFragmentID(fragmentID) {
    var URLBase = "play-audio://";
    window.location = URLBase + (fragmentID?encodeURIComponent(fragmentID):"")
}

/**
 Go To Element - scrolls the webview to the requested element
 */
function goToEl(el) {
    var top = document.body.scrollTop;
    var elTop = el.offsetTop - 20;
    var bottom = window.innerHeight + document.body.scrollTop;
    var elBottom = el.offsetHeight + el.offsetTop + 60

    if(elBottom > bottom || elTop < top) {
        document.body.scrollTop = el.offsetTop - 20
    }
    
    /* Set scroll left in case horz scroll is activated.
    
        The following works because el.offsetTop accounts for each page turned
        as if the document was scrolling vertical. We then divide by the window
        height to figure out what page the element should appear on and set scroll left
        to scroll to that page.
    */
    if( document.body.scrollTop == 0 ){
        var elLeft = document.body.clientWidth * Math.floor(el.offsetTop / window.innerHeight);
        document.body.scrollLeft = elLeft;
    }

    return el;
}

/**
 Remove All Classes - removes the given class from all elements in the DOM
 */
function removeAllClasses(className) {
    var els = document.body.getElementsByClassName(className)
    if( els.length > 0 )
    for( i = 0; i <= els.length; i++) {
        els[i].classList.remove(className);
    }
}

/**
 Audio Mark ID - marks an element with an ID with the given class and scrolls to it
 */
function audioMarkID(className, id) {
    if (audioMarkClass)
        removeAllClasses(audioMarkClass);

    audioMarkClass = className
    var el = document.getElementById(id);

    goToEl(el);
    el.classList.add(className)
}

function setMediaOverlayStyle(style){
    document.documentElement.classList.remove("mediaOverlayStyle0", "mediaOverlayStyle1", "mediaOverlayStyle2")
    document.documentElement.classList.add(style)
}

function setMediaOverlayStyleColors(color, colorHighlight) {
    var stylesheet = document.styleSheets[document.styleSheets.length-1];
    stylesheet.insertRule(".mediaOverlayStyle0 span.epub-media-overlay-playing { background: "+colorHighlight+" !important }")
    stylesheet.insertRule(".mediaOverlayStyle1 span.epub-media-overlay-playing { border-color: "+color+" !important }")
    stylesheet.insertRule(".mediaOverlayStyle2 span.epub-media-overlay-playing { color: "+color+" !important }")
}

var currentIndex = -1;


function findSentenceWithIDInView(els) {
    // @NOTE: is `span` too limiting?
    for(indx in els) {
        var element = els[indx];

        // Horizontal scroll
        if (document.body.scrollTop == 0) {
            var elLeft = document.body.clientWidth * Math.floor(element.offsetTop / window.innerHeight);
            // document.body.scrollLeft = elLeft;

            if (elLeft == document.body.scrollLeft) {
                currentIndex = indx;
                return element;
            }

        // Vertical
        } else if(element.offsetTop > document.body.scrollTop) {
            currentIndex = indx;
            return element;
        }
    }
    
    return null
}

function findNextSentenceInArray(els) {
    if(currentIndex >= 0) {
        currentIndex ++;
        return els[currentIndex];
    }
    
    return null
}

function resetCurrentSentenceIndex() {
    currentIndex = -1;
}

function getSentenceWithIndex(className) {
    var sentence;
    var sel = getSelection();
    var node = null;
    var elements = document.querySelectorAll("span.sentence");

    // Check for a selected text, if found start reading from it
    if (sel.toString() != "") {
        console.log(sel.anchorNode.parentNode);
        node = sel.anchorNode.parentNode;

        if (node.className == "sentence") {
            sentence = node

            for(var i = 0, len = elements.length; i < len; i++) {
                if (elements[i] === sentence) {
                    currentIndex = i;
                    break;
                }
            }
        } else {
            sentence = findSentenceWithIDInView(elements);
        }
    } else if (currentIndex < 0) {
        sentence = findSentenceWithIDInView(elements);
    } else {
        sentence = findNextSentenceInArray(elements);
    }

    var text = sentence.innerText || sentence.textContent;
    
    goToEl(sentence);
    
    if (audioMarkClass){
        removeAllClasses(audioMarkClass);
    }
    
    audioMarkClass = className;
    sentence.classList.add(className)
    return text;
}

function wrappingSentencesWithinPTags(){
    currentIndex = -1;
    "use strict";
    
    var rxOpen = new RegExp("<[^\\/].+?>"),
    rxClose = new RegExp("<\\/.+?>"),
    rxSupStart = new RegExp("^<sup\\b[^>]*>"),
    rxSupEnd = new RegExp("<\/sup>"),
    sentenceEnd = [],
    rxIndex;
    
    sentenceEnd.push(new RegExp("[^\\d][\\.!\\?]+"));
    sentenceEnd.push(new RegExp("(?=([^\\\"]*\\\"[^\\\"]*\\\")*[^\\\"]*?$)"));
    sentenceEnd.push(new RegExp("(?![^\\(]*?\\))"));
    sentenceEnd.push(new RegExp("(?![^\\[]*?\\])"));
    sentenceEnd.push(new RegExp("(?![^\\{]*?\\})"));
    sentenceEnd.push(new RegExp("(?![^\\|]*?\\|)"));
    sentenceEnd.push(new RegExp("(?![^\\\\]*?\\\\)"));
    //sentenceEnd.push(new RegExp("(?![^\\/.]*\\/)")); // all could be a problem, but this one is problematic
    
    rxIndex = new RegExp(sentenceEnd.reduce(function (previousValue, currentValue) {
                                            return previousValue + currentValue.source;
                                            }, ""));
    
    function indexSentenceEnd(html) {
        var index = html.search(rxIndex);
        
        if (index !== -1) {
            index += html.match(rxIndex)[0].length - 1;
        }
        
        return index;
    }

    function pushSpan(array, className, string, classNameOpt) {
        if (!string.match('[a-zA-Z0-9]+')) {
            array.push(string);
        } else {
            array.push('<span class="' + className + '">' + string + '</span>');
        }
    }
    
    function addSupToPrevious(html, array) {
        var sup = html.search(rxSupStart),
        end = 0,
        last;
        
        if (sup !== -1) {
            end = html.search(rxSupEnd);
            if (end !== -1) {
                last = array.pop();
                end = end + 6;
                array.push(last.slice(0, -7) + html.slice(0, end) + last.slice(-7));
            }
        }
        
        return html.slice(end);
    }
    
    function paragraphIsSentence(html, array) {
        var index = indexSentenceEnd(html);
        
        if (index === -1 || index === html.length) {
            pushSpan(array, "sentence", html, "paragraphIsSentence");
            html = "";
        }
        
        return html;
    }
    
    function paragraphNoMarkup(html, array) {
        var open = html.search(rxOpen),
        index = 0;
        
        if (open === -1) {
            index = indexSentenceEnd(html);
            if (index === -1) {
                index = html.length;
            }
            
            pushSpan(array, "sentence", html.slice(0, index += 1), "paragraphNoMarkup");
        }
        
        return html.slice(index);
    }
    
    function sentenceUncontained(html, array) {
        var open = html.search(rxOpen),
        index = 0,
        close;
        
        if (open !== -1) {
            index = indexSentenceEnd(html);
            if (index === -1) {
                index = html.length;
            }
            
            close = html.search(rxClose);
            if (index < open || index > close) {
                pushSpan(array, "sentence", html.slice(0, index += 1), "sentenceUncontained");
            } else {
                index = 0;
            }
        }
        
        return html.slice(index);
    }
    
    function sentenceContained(html, array) {
        var open = html.search(rxOpen),
        index = 0,
        close,
        count;
        
        if (open !== -1) {
            index = indexSentenceEnd(html);
            if (index === -1) {
                index = html.length;
            }
            
            close = html.search(rxClose);
            if (index > open && index < close) {
                count = html.match(rxClose)[0].length;
                pushSpan(array, "sentence", html.slice(0, close + count), "sentenceContained");
                index = close + count;
            } else {
                index = 0;
            }
        }
        
        return html.slice(index);
    }
    
    function anythingElse(html, array) {
        pushSpan(array, "sentence", html, "anythingElse");
        
        return "";
    }
    
    function guessSenetences() {
        var paragraphs = document.getElementsByTagName("p");

        Array.prototype.forEach.call(paragraphs, function (paragraph) {
            var html = paragraph.innerHTML,
                length = html.length,
                array = [],
                safety = 100;

            while (length && safety) {
                html = addSupToPrevious(html, array);
                if (html.length === length) {
                    if (html.length === length) {
                        html = paragraphIsSentence(html, array);
                        if (html.length === length) {
                            html = paragraphNoMarkup(html, array);
                            if (html.length === length) {
                                html = sentenceUncontained(html, array);
                                if (html.length === length) {
                                    html = sentenceContained(html, array);
                                    if (html.length === length) {
                                        html = anythingElse(html, array);
                                    }
                                }
                            }
                        }
                    }
                }

                length = html.length;
                safety -= 1;
            }

            paragraph.innerHTML = array.join("");
        });
    }
    
    guessSenetences();
}

function visible(elem) {
    return !(elem.clientHeight === 0 || elem.clientWidth === 0)
}

function getVisibleCFI() {
    let first;
    let firstOffY;
    //let allVisible = Array.from(document.querySelectorAll('body > *')).filter(visible)
    let allVisible = getLeafNodes(document).filter(visible)
    for(const elem of allVisible) {
        //Calculate the offset to the document
        //See: https://stackoverflow.com/a/18673641/7448536
        const offY = elem.getBoundingClientRect().top + document.documentElement.scrollTop
        if (first == null || offY < firstOffY) {
            first = elem;
            firstOffY = offY;
        }
    }
    var cfiStart = window.EPUBcfi.generateElementCFIComponent(first,[],["highlight"],[])

    window.webkit.messageHandlers.FolioReaderPage.postMessage("getVisibleCFI " + cfiStart + " " + first.outerHTML);
    
    return cfiStart
}

// Class based onClick listener

function addClassBasedOnClickListener(schemeName, querySelector, attributeName, selectAll) {
	if (selectAll) {
		// Get all elements with the given query selector
		var elements = document.querySelectorAll(querySelector);
		for (elementIndex = 0; elementIndex < elements.length; elementIndex++) {
			var element = elements[elementIndex];
			addClassBasedOnClickListenerToElement(element, schemeName, attributeName);
		}
	} else {
		// Get the first element with the given query selector
		var element = document.querySelector(querySelector);
		addClassBasedOnClickListenerToElement(element, schemeName, attributeName);
	}
}

function addClassBasedOnClickListenerToElement(element, schemeName, attributeName) {
	// Get the content from the given attribute name
	var attributeContent = element.getAttribute(attributeName);
	// Add the on click logic
	element.setAttribute("onclick", "onClassBasedListenerClick(\"" + schemeName + "\", \"" + encodeURIComponent(attributeContent) + "\");");
}

var onClassBasedListenerClick = function(schemeName, attributeContent) {
	// Prevent the browser from performing the default on click behavior
	event.preventDefault();
	// Don't pass the click event to other elemtents
	event.stopPropagation();
	// Create parameters containing the click position inside the web view.
	var positionParameterString = "/clientX=" + event.clientX + "&clientY=" + event.clientY;
	// Set the custom link URL to the event
	window.location = schemeName + "://" + attributeContent + positionParameterString;
}

function setFolioStyle(styleTextEncoded) {
    var styleText = window.atob(styleTextEncoded)
    var head = document.head
    var style = document.getElementById("style-folioreader-runtime")
    if (style == null) {
        style = document.createElement('style')
        style.type = "text/css"
        style.id = "style-folioreader-runtime"
        head.appendChild(style)
    }
    while (style.firstChild) {
        style.removeChild(style.firstChild)
    }
    style.appendChild(document.createTextNode(styleText))
    
//    window.webkit.messageHandlers.FolioReaderPage.postMessage("setFolioStyle " + style.outerHTML)

    var para = document.querySelector('p')
    var compStyles = window.getComputedStyle(para)
//    window.webkit.messageHandlers.FolioReaderPage.postMessage("setFolioStyle compStyles p " + compStyles.cssText)
}

//function injectHighlight() {    //sample data
////    var cfiStart = "/2/4/2/2/2/2/4/2/8/2/1:20";
////    var cfiEnd = "/2/4/2/2/2/2/4/2/8/2/1:41";
////    var cfiStart = "epubcfi(/10/2/4/2/2/2/2/4/2/8/2/1:20)"
////    var cfiEnd   = "epubcfi(/10/2/4/2/2/2/2/4/2/8/2/1:42)"
//                var cfiStart = "epubcfi(/4/2/2/2/2/4/2/8/2/1)"
//                var startNode = window.EPUBcfi.getTargetElementWithPartialCFI(encodeURI(cfiStart), document, [], [], []).get(0)
//                window.webkit.messageHandlers.FolioReaderPage.postMessage("injectHighlight startNode " + startNode + " " + startNode.outerHTML)
//
//    var cfiEnd   = "epubcfi(/4/2/2/2/2/4/2/8/2/1)"
//    var endNode   = window.EPUBcfi.getTargetElementWithPartialCFI(encodeURI(cfiEnd),   document, [], [], []).get(0)
//    window.webkit.messageHandlers.FolioReaderPage.postMessage("injectHighlight endNode " + endNode + " " + endNode.outerHTML)
//
//                var range = document.createRange()
//                range.setStart(startNode, 20)
//                range.setEnd(endNode, 42)
//                window.webkit.messageHandlers.FolioReaderPage.postMessage("injectHighlight range " + range)
//
//                var selectionContents = range.extractContents();
//                var elm = document.createElement("highlight");
//                var id = guid();
//
//                elm.appendChild(selectionContents);
//                elm.setAttribute("id", id);
//                elm.setAttribute("onclick","callHighlightURL(this);");
//                elm.setAttribute("class", "highlight-yellow");
//
//                range.insertNode(elm);
//                window.webkit.messageHandlers.FolioReaderPage.postMessage("injectHighlight finished " + range + " " + elm)
//
//}
                                                                
                                                                
//window.webkit.messageHandlers.FolioReaderPage.postMessage("Original " + getHTML() + "\n" + "---------------------------------------\n")

//removeOuterTable()
//
//window.webkit.messageHandlers.FolioReaderPage.postMessage("After removeOuterTable " + getHTML())
//
//removePSpace()
//
//window.webkit.messageHandlers.FolioReaderPage.postMessage("After removePSpace " + getHTML())
//
//removeBodyClass()
//
//window.webkit.messageHandlers.FolioReaderPage.postMessage("After removeBodyClass " + getHTML())
//
//reParagraph()
//
//window.webkit.messageHandlers.FolioReaderPage.postMessage("After reParagraph " + getHTML())
//tweakStyleOnly()
//window.webkit.messageHandlers.FolioReaderPage.postMessage("After tweakStyleOnly " + getHTML())
                                                                
window.webkit.messageHandlers.FolioReaderPage.postMessage("BridgeFinished");

//injectHighlight()


