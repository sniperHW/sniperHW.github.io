window.onload=colorChange;

	var thisImg=0;
	function rotate(){

	var sImages=new Array("images/slider.jpg","images/slider1.jpg");
	thisImg++;
	if(thisImg==sImages.length){
		thisImg=0;
	}
	document.getElementById("sliderImg").src=sImages[thisImg];
	setTimeout(rotate,2*1000);
}
function colorChange(){
	var bgChange=document.getElementsByTagName("ul");
	for(var k=0;k<bgChange.length;k++){
		var bgChange2=bgChange[k];
	    for(var i=0;i<bgChange2.childNodes.length;i++){
		   var bgChanges=bgChange2.childNodes[i];
		   if(bgChanges.tagName == "A"){
		       for(var j=0;j<bgChanges.childNodes.length;j++){
		           bgChanges.childNodes[j].onmouseover=changeColorover;
		           bgChanges.childNodes[j].onmouseout=changeColorout;
		       }
	       }
	    }
	}
	var bgChange1=document.getElementById("name");
	bgChange1.onmouseover=function(){this.style.background="#fff";};
	bgChange1.onmouseout=function(){this.style.background="#f3dfba";};
	rotate();	
}
function changeColorover(){
	if(this.parentNode.parentNode.className=="nav"){
	     this.style.background="#fff";
	}
	else{
		this.style.background="#e9e9e9";
	}
} 
function changeColorout(){
	if(this.parentNode.parentNode.className=="nav"){
	    this.style.background="#f3dfba";
	}
	else{
		this.style.background="#fff";
	}
} 