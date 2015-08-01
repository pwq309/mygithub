/**
 * Created by RibPan on 2015/7/28.
 */
function showNumberWithAnimation(i,j,randNumber){
    //通过id取到相应number cell的元素
    var numberCell = $('#number-cell-' + i + "-" + j);
    //改变number cell取值后的外观
    numberCell.css('background-color',getNumberBackgroundColor(randNumber));
    numberCell.css('color',getNumberColor(randNumber));
    numberCell.text(randNumber);
    //添加动画效果
    numberCell.animate({
        width:cellSlideLength,
        height:cellSlideLength,
        top:getPosTop(i,j),
        left:getPosLeft(i,j)
    },50);
}
function showMoveAnimation(fromx,fromy,tox,toy){
    var numberCell = $('#number-cell-' + fromx + '-' + fromy);
    numberCell.animate({
        top:getPosTop(tox,toy),
        left:getPosLeft(tox,toy)
    },200);
}

function updateScore(score){
    $("#score").text(score);
}