/**
 * Created by hp-4441s on 2015/7/19.
 */
function addLoadEvent(func){
    var oldonload=window.onload;
    if(typeof window.onload!='function') {
        window.onload=func;
    }else{
        window.onload=function(){
            oldonload();
            func();
        }
    }
}