/**
 * Created by RibPan on 2015/7/28.
 */
var board = new Array();
var score = 0;
//一个格子每次只能进行一次叠加
var hasConflicted = new Array();

var startx = 0;
var starty = 0;
var endx = 0;
var endy = 0;

$(document).ready(function(){
    prepareForMobile();
    newgame();
});

function prepareForMobile(){
    //如果当前设备屏幕宽度大于500个像素，就不自适应屏幕了
    if(documentWidth > 500){
        gridContainerWidth = 500;
        cellSpace = 20;
        cellSlideLength = 100;
    }
    //先对大格子进行尺寸调整
    $('#grid-container').css('width',gridContainerWidth - 2*cellSpace);
    $('#grid-container').css('height',gridContainerWidth - 2*cellSpace);
    $('#grid-container').css('padding',cellSpace);
    $('#grid-container').css('board-radius',0.02*gridContainerWidth);

    $('.grid-cell').css('width',cellSlideLength);
    $('.grid-cell').css('height',cellSlideLength);
    $('.grid-cell').css('border-radius',0.02*cellSlideLength);
}

function newgame(){
    //初始化棋盘格
    init();
    //再随机两个格子生成数字
    generateOneNumber();
    generateOneNumber();
}
function init(){
    for( var i = 0; i < 4; i ++ ) {
        for (var j = 0; j < 4; j++) {
            var gridCell = $('#grid-cell-' + i + "-" + j);
            //传入i和j的坐标值来计算相应的top值
            gridCell.css('top', getPosTop(i, j));
            //传入i和j的坐标值来计算相应的left值
            gridCell.css('left', getPosLeft(i, j));
        }
    }
    for(var i = 0;i < 4;i ++ ){
        board[i] = new Array();
        hasConflicted[i] = new Array();
        for(var j = 0;j < 4;j ++ ){
            board[i][j] = 0;
            //初始情况下每一个位置都没发生过碰撞
            hasConflicted[i][j] = false;
        }
    }
    //通知前端根据board值对number cell元素进行操作
    updateBoardView();

    score = 0;
}
function updateBoardView(){
    //如果当前游戏里有number cell元素，就全删掉
    $(".number-cell").remove();
    //遍历board元素，根据board元素设定相应的number cell值
    for(var i = 0; i< 4; i ++ ) {
        for (var j = 0; j < 4; j++) {
            $("#grid-container").append('<div class="number-cell" id="number-cell-' + i + '-' + j + '"></div>');
            var theNumberCell = $('#number-cell-' + i + '-' + j);
            if (board[i][j] == 0) {
                theNumberCell.css('width', '0px');
                theNumberCell.css('height', '0px');
                //放到每一个grid cell中间
                theNumberCell.css('top', getPosTop(i, j) + cellSlideLength/2);
                theNumberCell.css('left', getPosLeft(i, j) + cellSlideLength/2);
            }
            else {
                theNumberCell.css('width', cellSlideLength);
                theNumberCell.css('height', cellSlideLength);
                theNumberCell.css('top', getPosTop(i, j));
                theNumberCell.css('left', getPosLeft(i, j));
                //数字不一样 背景色也不一样 传入相应board值
                theNumberCell.css('background-color', getNumberBackgroundColor(board[i][j]));
                //传入board[i][j]值 改变前景色
                theNumberCell.css('color', getNumberColor(board[i][j]));
                //number cell显示数字的值
                theNumberCell.text(board[i][j]);
            }

            hasConflicted[i][j] = false;
        }
    }
    //要在number-cell里写文字，要对行高和字号进行设置
    $('.number-cell').css('line-height',cellSlideLength+'px');
    $('.number-cell').css('font-size',0.6*cellSlideLength+'px');
}

function generateOneNumber(){
    //判断当前棋盘格有没有空间生成数字
    if(nospace(board))
        return false;
    //随机一个位置
    var randx = parseInt(Math.floor( Math.random() * 4));
    var randy = parseInt(Math.floor( Math.random() * 4));

    var times = 0;
    //只让计算机猜50次随机位置
    while(times < 50){
        if(board[randx][randy] == 0)
            break;

        randx = parseInt(Math.floor(Math.random() * 4));
        randy = parseInt(Math.floor(Math.random() * 4));

        times ++;
    }
    //如果50次都没猜中一个空白位置，就人工产生。挨个格子去找
    if( times == 50){
        for(var i = 0; i < 4; i ++){
            for( var j = 0; j < 4; j ++){
                if( board[i][j] == 0){
                    randx = i;
                    randy = j;
                }
            }
        }
    }
    //随机一个数字
    var randNumber = Math.random() < 0.5 ? 2:4;
    //在随机的位置显示数字
    board[randx][randy] = randNumber;
    showNumberWithAnimation(randx,randy,randNumber);

    return true;
}
//绑定按下按键的事件
$(document).keydown(function(event){
    switch(event.keyCode){
        case 37: //left
            //阻挡默认效果，防止按上下键页面跟着动
            event.preventDefault();
            if(moveleft()){
                setTimeout("generateOneNumber()",210);
                setTimeout("isgameover()",300);
            };
            break;
        case 38: //up
            //阻挡默认效果，防止按上下键页面跟着动
            event.preventDefault();
            if(moveup()){
                setTimeout("generateOneNumber()",210);
                setTimeout("isgameover()",300);
            };
            break;
        case 39: //right
            //阻挡默认效果，防止按上下键页面跟着动
            event.preventDefault();
            if(moveright()){
                setTimeout("generateOneNumber()",210);
                setTimeout("isgameover()",300);
            };
            break;
        case 40: //down
            //阻挡默认效果，防止按上下键页面跟着动
            event.preventDefault();
            if(movedown()){
                setTimeout("generateOneNumber()",210);
                setTimeout("isgameover()",300);
            };
            break;
        default: //default
            break;
    }
});

//添加监听事件
document.addEventListener('touchstart',function(event){
    //获得手指触摸点的xy坐标
    startx=event.touches[0].pageX;
    starty=event.touches[0].pageY;
});
document.addEventListener('touchmove',function(event){
    event.preventDefault();
});
document.addEventListener('touchend',function(event){
    //获得手指离开屏幕的点的xy坐标
    endx=event.changedTouches[0].pageX;
    endy=event.changedTouches[0].pageY;

    var deltax = endx - startx;
    var deltay = endy - starty;
    //如果用户手指滑动距离小于屏幕尺寸的0.3，则不认为是有效滑动
    if(Math.abs(deltax)<0.2*documentWidth && Math.abs(deltay)<0.2*documentWidth)
        return;
    //slide in x direction
    if(Math.abs(deltax) >= Math.abs(deltay)){
        if(deltax>0){
            //move right
            if(moveright()){
                setTimeout("generateOneNumber()",210);
                setTimeout("isgameover()",300);
            };
        }
        else{
            //move left
            if(moveleft()){
                setTimeout("generateOneNumber()",210);
                setTimeout("isgameover()",300);
            };
        }
    }
    //slide in y direction
    else{
        if(deltay>0){
            //move down
            if(movedown()){
                setTimeout("generateOneNumber()",210);
                setTimeout("isgameover()",300);
            };
        }
        else{
            //move up
            if(moveup()){
                setTimeout("generateOneNumber()",210);
                setTimeout("isgameover()",300);
            };
        }

    }
});

function isgameover(){
    //如果棋盘格没空间了，且没有能移动的数字了，游戏结束
    if(nospace(board) && nomove(board)){
        gameover();
    }
}

function gameover(){
    alert("Game Over!");
}

function moveleft(){
    if(!canMoveLeft(board)){
        return false;
    }
    //moveleft
    for(var i = 0; i <4 ; i ++) {
        for (var j = 1; j < 4; j++) {
            if (board[i][j] != 0) {
                //遍历ij所有的左侧的元素，考察ik是不是移动的落脚点,如果为0，且右侧没有障碍物，则可以落脚
                for (var k = 0; k < j; k++) {
                    if (board[i][k] == 0 && noBlockHorizontal(i, k, j, board)) {
                        //move
                        showMoveAnimation(i, j, i, k);
                        board[i][k] = board[i][j];
                        board[i][j] = 0;
                        continue;
                    }
                    //ik和ij上的数字相等，且ik到ij之间没有障碍物
                    else if (board[i][k] == board[i][j] && noBlockHorizontal(i, k, j, board) && !hasConflicted[i][k]) {
                        //move
                        showMoveAnimation(i, j, i, k);
                        //add
                        board[i][k] += board[i][j];
                        board[i][j] = 0;
                        //add score
                        score += board[i][k];
                        updateScore(score);

                        hasConflicted[i][k] = true;
                        continue;
                    }
                }
            }
        }
    }
    //等待200ms更新board，让动画播放
    setTimeout("updateBoardView()",200);
    return true;
}

function moveup(){
    if(!canMoveUp(board)){
        return false;
    }
    //moveup
    for(var j = 0; j <4 ; j ++) {
        for (var i = 1; i < 4; i++) {
            if (board[i][j] != 0) {
                //遍历ij所有的上侧的元素，考察kj是不是移动的落脚点,如果为0，且下侧没有障碍物，则可以落脚
                for (var k = 0; k < i; k++) {
                    if (board[k][j] == 0 && noBlockVertical(j, k, i, board)) {
                        //move
                        showMoveAnimation(i, j, k, j);
                        board[k][j] = board[i][j];
                        board[i][j] = 0;
                        continue;
                    }
                    //kj和ij上的数字相等，且kj到ij之间没有障碍物
                    else if (board[k][j] == board[i][j] && noBlockVertical(j, k, i, board) && !hasConflicted[k][j]) {
                        //move
                        showMoveAnimation(i, j, k, j);
                        //add
                        board[k][j] += board[i][j];
                        board[i][j] = 0;
                        //add score
                        score += board[k][j];
                        updateScore(score);

                        hasConflicted[k][j] = true;
                        continue;
                    }
                }
            }
        }
    }
    //等待200ms更新board，让动画播放
    setTimeout("updateBoardView()",200);
    return true;
}

function moveright(){
    if(!canMoveRight(board)){
        return false;
    }
    //moveright
    for(var i = 0; i <4 ; i ++) {
        for (var j = 2; j>=0; j--) {
            if (board[i][j] != 0) {
                //遍历ij所有的右侧的元素，考察ik是不是移动的落脚点,如果为0，且右侧没有障碍物，则可以落脚
                for (var k = 3; k > j; k--) {
                    if (board[i][k] == 0 && noBlockHorizontal(i, j, k, board)) {
                        //move
                        showMoveAnimation(i, j, i, k);
                        board[i][k] = board[i][j];
                        board[i][j] = 0;
                        continue;
                    }
                    //ik和ij上的数字相等，且ik到ij之间没有障碍物
                    else if (board[i][k] == board[i][j] && noBlockHorizontal(i, j, k, board) && !hasConflicted[i][k]) {
                        //move
                        showMoveAnimation(i, j, i, k);
                        //add
                        board[i][k] += board[i][j];
                        board[i][j] = 0;
                        //add score
                        score += board[i][k];
                        updateScore(score);

                        hasConflicted[i][k] = true;
                        continue;
                    }
                }
            }
        }
    }
    //等待200ms更新board，让动画播放
    setTimeout("updateBoardView()",200);
    return true;
}

function movedown(){
    if(!canMoveDown(board)){
        return false;
    }
    //movedown
    for(var j = 0; j <4 ; j ++) {
        for (var i = 2; i >=0; i--) {
            if (board[i][j] != 0) {
                //遍历ij所有的下侧的元素，考察kj是不是移动的落脚点,如果为0，且上侧没有障碍物，则可以落脚
                for (var k = 3; k > i; k--) {
                    if (board[k][j] == 0 && noBlockVertical(j, i, k, board)) {
                        //move
                        showMoveAnimation(i, j, k, j);
                        board[k][j] = board[i][j];
                        board[i][j] = 0;
                        continue;
                    }
                    //kj和ij上的数字相等，且kj到ij之间没有障碍物
                    else if (board[k][j] == board[i][j] && noBlockVertical(j, i, k, board) && !hasConflicted[k][j]) {
                        //move
                        showMoveAnimation(i, j, k, j);
                        //add
                        board[k][j] += board[i][j];
                        board[i][j] = 0;
                        //add score
                        score += board[k][j];
                        updateScore(score);

                        hasConflicted[k][j] = true;
                        continue;
                    }
                }
            }
        }
    }
    //等待200ms更新board，让动画播放
    setTimeout("updateBoardView()",200);
    return true;
}