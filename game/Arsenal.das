module Arsenal
require GameObject


class ArsenalWhip:GameObject

    def override update(delta:float):void
        GameObject`update(self,delta)

    def override draw(){}