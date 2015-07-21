/**
 * Created by hp-4441s on 2015/7/12.
 */
$(function(){
    var $html_ani = $(".skill-bar-html");
    $(".skill-bar-wrap-html").hover(function(){
        $html_ani.stop().animate({width: "75%"},1500);
    },function(){
        $html_ani.stop().animate({width: "0%"}, 1500);
    })
})

$(function(){
    var $css_ani = $(".skill-bar-css");
    $(".skill-bar-wrap-css").hover(function(){
        $css_ani.stop().animate({width: "70%"},1500);
    },function(){
        $css_ani.stop().animate({width: "0%"},1500);
    })
})

$(function(){
    var $js_ani = $(".skill-bar-js");
    $(".skill-bar-wrap-js").hover(function(){
        $js_ani.stop().animate({width: "65%"},1500);
    },function(){
        $js_ani.stop().animate({width: "0%"},1500);
    })
})

$(function(){
    var $perl_ani = $(".skill-bar-perl");
    $(".skill-bar-wrap-perl").hover(function(){
        $perl_ani.stop().animate({width: "70%"},1500);
    },function(){
        $perl_ani.stop().animate({width: "0%"},1500);
    })
})

$(function(){
    var $c_ani = $(".skill-bar-c");
    $(".skill-bar-wrap-c").hover(function(){
        $c_ani.stop().animate({width: "85%"},1500);
    },function(){
        $c_ani.stop().animate({width: "0%"},1500);
    })
})

$(function(){
    var $jquery_ani = $(".skill-bar-jquery");
    $(".skill-bar-wrap-jquery").hover(function(){
        $jquery_ani.stop().animate({width: "70%"},1500);
    },function(){
        $jquery_ani.stop().animate({width: "0%"},1500);
    })
})

$(function(){
    var $category = $("ul.awout li");
    $category.hide();
    var $toggleBtn = $('div.showaward > a');
    $toggleBtn.click(function(){
        if($category.is(":visible")) {
            $category.hide(200);
        }else{
            $category.show(200);
        }
    })
})

$(function(){
    var $category = $("ul.selfout li");
    $category.hide();
    var $toggleBtn = $('div.selfcmt > a');
    $toggleBtn.click(function(){
        if($category.is(":visible")) {
            $category.hide(200);
        }else{
            $category.show(200);
        }
    })
})

$(function(){
    var $category = $("ul.intout li");
    $category.hide();
    var $toggleBtn = $('div.interest > a');
    $toggleBtn.click(function(){
        if($category.is(":visible")) {
            $category.hide(200);
        }else{
            $category.show(200);
        }
    })
})