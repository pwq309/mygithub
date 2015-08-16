/**
 * Created by hp-4441s on 2015/7/18.
 */
function insertAfter(newElement,targetElement){        //通用型函数，在一个元素节点之后插入新元素
    var parent = targetElement.parentNode;
    if(parent.lastChild==targetElement){
        parent.appendChild(newElement);
    } else{
        parent.insertBefore(newElement,targetElement.nextSibling);
    }
}
function prepareplaceholder(){                    //创建一个img元素和p元素，插入到节点树图片库清单后面
    if(!document.createElement) return false;
    if(!document.createTextNode) return false;
    if(!document.getElementById) return false;
    if(!document.getElementById("imagegallery")) return false;
    var placeholder=document.createElement("img");            //创建元素节点
    placeholder.setAttribute("id","placeholder");
    placeholder.setAttribute("src","img/dog.jpg");
    placeholder.setAttribute("alt","my image gallery");
    var para=document.createElement("p");
    para.setAttribute("id","description");
    var text=document.createTextNode("Choose an image.");     //创建文本节点
    para.appendChild(text);
    var gallery=document.getElementById("imagegallery")
    insertAfter(placeholder,gallery);
    insertAfter(para,placeholder);
    //document.getElementsByTagName("body")[0].appendChild(placeholder);
    //document.body.appendChild(para);
}
function showPic(whichpic){                     //把占位符图片替换为目标图片
    if(!document.getElementById("placeholder")) return false;
    var source = whichpic.getAttribute("href");     //获取用于替换的属性
    var placeholder = document.getElementById("placeholder");  //获取被替换的对象
    if(placeholder.nodeName!="IMG") return false;
    placeholder.setAttribute("src",source);      //替换对象的src
    if(document.getElementById("description")) {
        var text = whichpic.getAttribute("title")?whichpic.getAttribute("title"):"";
        var description = document.getElementById("description");
        //alert(description.firstChild.nodeValue);
        if(description.firstChild.nodeType==3) {
            description.firstChild.nodeValue = text;
        }
        //alert(description.firstChild.nodeValue);
    }
    return true;
}
function prepareGallery(){                       //给列表中每一项添加onclick属性
    if(!document.getElementsByTagName) return false;
    if(!document.getElementById) return false;
    if(!document.getElementById("imagegallery")) return false;
    var gallery=document.getElementById("imagegallery");
    var links=gallery.getElementsByTagName("a");
    for(var i=0;i<links.length;i++){
        links[i].onclick=function(){
            return showPic(this)?false:true;     //如果showPic返回true，我们就返回false，浏览器不会打开链接
        }                              //如果返回false，认为图片还没有更新，于是返回true允许默认行为发生
    }
}
function addLoadEvent(func){                        //通用型函数，非常实用的脚本
    var oldonload=window.onload;                    //在页面加载结束后执行多个function
    if(typeof window.onload!='function') {
        window.onload=func;
    }else {
        window.onload=function(){
            oldonload();
            func();
        }
    }
}
addLoadEvent(prepareplaceholder);
addLoadEvent(prepareGallery);
/*
window.onload = function(){
    if(!document.getElementsByTagName) return false;
    var links = document.getElementsByClassName("a");
    for (var i=0;i<links.length;i++){
        if(links[i].getAttribute("class") == "popup"){
            links[i].onclick=function(){
                popup(this.getAttribute("href"));
                return false;
            }
        }
    }
}
function popup(winURL){
    window.open(winURL,"popup","width=320,height=480");
}
*/
/*
function countBodyChildren(){
    var body_element = document.getElementsByTagName("body")[0];
    alert(body_element.childNodes.length);
}
window.onload = countBodyChildren;

function bodynodetype(){
    var body_elelment = document.getElementsByTagName("body")[0];
    alert(body_elelment.nodeType);
}
window.onload = bodynodetype;
*/