/**
 * Created by RibPan on 2015/7/23.
 */
function displayResult(){
    //取得所有缩略词
    var jiandao = document.getElementById("jiandao");
    var shitou = document.getElementById("shitou");
    var bu = document.getElementById("bu");
    var jiandaoUrl = jiandao.getAttribute("src");
    var shitouUrl = shitou.getAttribute("src");
    var buUrl = bu.getAttribute("src");
    var threeImg = document.getElementById("threeImg");
    var links = threeImg.getElementsByTagName("img");
    var myresult = document.getElementById("my-result");
    var computerresult = document.getElementById("computer-result");
    var resulttext = document.getElementById("result-text");
    var vs = document.getElementById("vs");
    var tie = document.getElementById("tie");
    var win = document.getElementById("win");
    var lose = document.getElementById("lose");
    var x = 0;
    var y = 0;
    var z = 0;
    //一个二维数组用来存储比较结果，第一层索引是电脑出拳动作，第二层索引是玩家出拳动作
    var beats = [["Tie!","You win!","You lose!"],
                 ["You lose!","Tie!","You win!"],
                 ["You win!","You lose!","Tie!"]];
    //产生一个数组，用来保存三张图片的URL，由随机数决定电脑的输出
    var choice = [jiandaoUrl,shitouUrl,buUrl];
    //为剪刀石头布三张图片添加onclick属性
    threeImg.onclick = function(ev){
        if(ev.target.tagName == "img" || ev.target.tagName == "IMG") {
            for (var i = 0; i < links.length; i++) {
                if (links[i] == ev.target) {
                    var currentImgUrl = links[i].getAttribute("src");
                    myresult.setAttribute("src", currentImgUrl);
                    //产生一个0~2的随机数
                    var comrlt = Math.floor(Math.random() * 3);
                    computerresult.setAttribute("src", choice[comrlt]);
                    resulttext.innerHTML = beats[comrlt][i];
                    vs.style.display = "inline-block";
                    if (comrlt == i) {
                        tie.innerHTML = ++x;
                        myresult.style.borderColor = "#7fff00";
                        computerresult.style.borderColor = "#7fff00";
                    } else if ((comrlt==2 && i==0) || (comrlt==1 && i==2) || (comrlt==0 && i==1)) {
                        win.innerHTML = ++y;
                        myresult.style.borderColor = "#ff4500";
                        computerresult.style.borderColor = "#a9a9a9";
                    } else {
                        lose.innerHTML = ++z;
                        myresult.style.borderColor = "#a9a9a9";
                        computerresult.style.borderColor = "#ff4500";
                    }
                }
            }
        }
    }
}
addLoadEvent(displayResult);