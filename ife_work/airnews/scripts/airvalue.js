/**
 * Created by RibPan on 2015/7/28.
 */
aqi_list = {"2014-12":[11,11,3,4,2,0],"2014-10":[5,9,4,3,6,4],"2014-11":[6,9,7,2,5,1],"2014-8":[5,15,6,5,0,0],"2014-9":[6,13,7,4,0,0],"2014-1":[5,7,9,8,1,1],"2014-2":[5,2,8,2,3,8],"2014-3":[5,11,3,7,4,1],"2014-4":[0,13,9,5,3,0],"2014-5":[3,14,11,3,0,0],"2014-6":[3,19,5,3,0,0],"2014-7":[3,9,6,8,5,0]};

chinese = ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十", "十一", "十二"];

// 创建图表
for(var month = 1; month <= 12; month++) {
    date = "2014-"+month.toString();

    col = $("<li class=\"bar\" id=\""+date+"\">");
    $(col).append("<span class=\"month\">"+chinese[month-1]+"月</span>")

    for(var level = 1; level <= 6; level++) {
        $(col).append("<span class=\"level"+level+" subbar\"></span>")
    }
    $(".chart").append(col);
}

// 添加动画
for(var month = 1; month <= 12; month++) {
    date = "2014-"+month.toString();

    $("#"+date+">span.subbar").each(function(index, element) {
        $(this).animate({width: ((aqi_list[date][index]*10).toString()+"px")}, "slow");
    });
}

// 添加天数指示
$(".chart .subbar").mousemove(function() {
    $(".numbar").remove();

    x = event.pageX;
    y = event.pageY;
    elewidth = parseInt($(this).css("width"));

    days = elewidth/10;
    bar = $("<div class=\"numbar\"></div>");
    $(bar).text(days);
    $(bar).css({left: x-20, top: y-25});
    $(".chart").append(bar);
});

$(".chart .subbar").mouseout(function() {
    $(".numbar").remove();
})