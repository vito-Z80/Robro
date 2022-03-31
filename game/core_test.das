

var time:float
def turrelAction(delta:float; var obj:GameObject?)
    var a=rnd(3)
    time+=delta
    if time >= 1f
        time = 0f
        print("TURREL: {a}\n")