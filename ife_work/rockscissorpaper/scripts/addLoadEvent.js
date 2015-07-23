/**
 * Created by RibPan on 2015/7/22.
 */
function addLoadEvent(func){
    var oldonload = window.onload;
    if(typeof window.onload != "function"){
        window.onload = func;
    }else {
        window.onload = function(){
            oldonload();
            func();
        }
    }
}