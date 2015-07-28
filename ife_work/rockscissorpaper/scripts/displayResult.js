/**
 * Created by RibPan on 2015/7/22.
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
    links[0].onclick = function(){
        var currentImgUrl = this.getAttribute("src");
        myresult.setAttribute("src",currentImgUrl);
        //产生一个0~2的随机数
        var comrlt0 = Math.floor(Math.random()*3);
        computerresult.setAttribute("src",choice[comrlt0]);
        vs.style.display = "inline-block";
        resulttext.innerHTML = beats[comrlt0][0];
        if(comrlt0==0){
            tie.innerHTML = ++x;
        } else if(comrlt0==1){
            win.innerHTML = ++y;
        } else if(comrlt0==2){
            lose.innerHTML = ++z;
        }
    }
    links[1].onclick = function(){
        var currentImgUrl = this.getAttribute("src");
        myresult.setAttribute("src",currentImgUrl);
        //产生一个0~2的随机数
        var comrlt1 = Math.floor(Math.random()*3);
        computerresult.setAttribute("src",choice[comrlt1]);
        vs.style.display = "inline-block";
        resulttext.innerHTML = beats[comrlt1][1];
        if(comrlt1==0){
            lose.innerHTML = ++z;
        } else if(comrlt1==1){
            tie.innerHTML = ++x;
        } else if(comrlt1==2){
            win.innerHTML = ++y;
        }
    }
    links[2].onclick = function(){
        var currentImgUrl = this.getAttribute("src");
        myresult.setAttribute("src",currentImgUrl);
        //产生一个0~2的随机数
        var comrlt2 = Math.floor(Math.random()*3);
        computerresult.setAttribute("src",choice[comrlt2]);
        vs.style.display = "inline-block";
        resulttext.innerHTML = beats[comrlt2][2];
        if(comrlt2==0){
            win.innerHTML = ++y;
        } else if(comrlt2==1){
            lose.innerHTML = ++z;
        } else if(comrlt2==2){
            tie.innerHTML = ++x;
        }
    }
}
addLoadEvent(displayResult);