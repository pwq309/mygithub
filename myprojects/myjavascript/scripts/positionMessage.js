/**
 * Created by hp-4441s on 2015/7/20.
 */
function positionMessage(){
    if(!document.getElementById) return false;
    if(!document.getElementById("message")) return false;
    var elem=document.getElementById("message");
    elem.style.position="absolute";
    elem.style.left="50px";
    elem.style.top="100px";
    if(!document.getElementById("message2")) return false;
    var elem2 = document.getElementById("message2");
    elem2.style.position = "absolute";
    elem2.style.left = "50px";
    elem2.style.top = "200px";
    moveElement("message2",200,250,20)
    moveElement("message",200,50,20);
}
addLoadEvent(positionMessage);