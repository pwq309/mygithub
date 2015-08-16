/**
 * Created by hp-4441s on 2015/7/19.
 */
function displayCitation(){
    if(!document.getElementsByTagName) return false;
    if(!document.createElement) return false;
    if(!document.createTextNode) return false;
    //取得所有引用
    var quotes = document.getElementsByTagName("blockquote");
    //遍历引用
    for (var i=0;i<quotes.length;i++){
    //如果没有cite属性，继续下一次的循环
        if(!quotes[i].getAttribute("cite")) continue;
    //保存cite属性
        var url=quotes[i].getAttribute("cite");
    //取得引用中的所有元素节点
        var quoteChildren=quotes[i].getElementsByTagName("*");
    //如果没有元素节点，继续下一次循环
        if(quoteChildren.length<1) continue;
    //取得引用中的最后一个元素节点
        var elem = quoteChildren[quoteChildren.length-1];
    //创建标记
        var link = document.createElement("a");
        var link_text = document.createTextNode("source");
        link.appendChild(link_text);
        link.setAttribute("href",url);
        var superscript=document.createElement("sup");
        superscript.appendChild(link);
    //把标记添加到引用中的最后一个元素节点
        elem.appendChild(superscript);
    }
}
addLoadEvent(displayCitation);