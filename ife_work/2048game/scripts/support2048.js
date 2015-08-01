/**
 * Created by RibPan on 2015/7/28.
 */
//取得运行设备的宽度
documentWidth = window.screen.availWidth;
//定义4X4棋盘格的宽度
gridContainerWidth = 0.92 * documentWidth;
//定义每一个小方格的宽度
cellSlideLength = 0.18 * documentWidth;
//定义小方格之间的间距
cellSpace = 0.04 * documentWidth;

function getPosTop(i,j){
    return cellSpace+(cellSpace+cellSlideLength)*i;
}
function getPosLeft(i,j){
    return cellSpace+(cellSpace+cellSlideLength)*j;
}
//传入number值 选择不同的颜色
function getNumberBackgroundColor(number){
    switch(number){
        case 2:return "#eee4da";break;
        case 4:return "#ede0c8";break;
        case 8:return "#f2b179";break;
        case 16:return "#f59563";break;
        case 32:return "#f67e5f";break;
        case 64:return "#f65e3b";break;
        case 128:return "#edcf72";break;
        case 256:return "#edcc61";break;
        case 512:return "#9c0";break;
        case 1024:return "#33b5e5";break;
        case 2048:return "#09c";break;
        case 4096:return "#a6e";break;
        case 8192:return "93e";break;
    }
    return "black";
}
//前景色 2和4的时候是一种颜色，其他时候都是白色
function getNumberColor(number){
    if(number <= 4)
        return "#776e65";

    return "white";
}

//判断当前有没有空间的函数
function nospace(board){
    for(var i = 0; i < 4; i ++)
        for (var j = 0; j < 4; j++)
            if (board[i][j] == 0)
                return false;

    return true;
}
function canMoveLeft(board){
    for(var i = 0; i < 4; i++ ){
        //第一列不能左移
        for(var j = 1;j < 4; j ++){
            if(board[i][j] != 0){
                if(board[i][j-1] == 0 || board[i][j-1] == board[i][j]){
                    return true;
                }
            }
        }
    }
    return false;
}
function canMoveUp(board){
    for(var i = 1; i < 4; i++ ){
        //第一行不能上移
        for(var j = 0;j < 4; j ++){
            if(board[i][j] != 0){
                if(board[i-1][j] == 0 || board[i-1][j] == board[i][j]){
                    return true;
                }
            }
        }
    }
    return false;
}

function canMoveRight(board){
    for(var i = 0; i < 4; i++ ){
        //最后一列不能右移
        for(var j = 0;j < 3; j++){
            if(board[i][j] != 0){
                if(board[i][j+1] == 0 || board[i][j+1] == board[i][j]){
                    return true;
                }
            }
        }
    }
    return false;
}

function canMoveDown(board){
    for(var i = 0; i < 3; i++ ){
        //最后一行不能下移
        for(var j = 0;j < 4; j ++){
            if(board[i][j] != 0){
                if(board[i+1][j] == 0 || board[i+1][j] == board[i][j]){
                    return true;
                }
            }
        }
    }
    return false;
}

function noBlockHorizontal(row,col1,col2,board){
    for(var i = col1 + 1; i < col2; i++){
        if(board[row][i] != 0){
            return false;
        }
    }
    return true;
}

function noBlockVertical(col,row1,row2,board){
    for(var i = row1 + 1; i < row2; i++){
        if(board[i][col] != 0){
            return false;
        }
    }
    return true;
}

function nomove(board){
    if( canMoveLeft(board) ||
        canMoveRight(board) ||
        canMoveUp(board) ||
        canMoveDown(board)){
        return false;
    }
    return true;
}