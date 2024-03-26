import 'package:flutter/material.dart';

class IcAttribute<T>{
    IcAttribute({
        required this.prefix,
        required this.instName,
        this.spiceModel,
        this.value,
        this.value2,
        this.spiceLine,
        this.spiceLine2        
    }

    );


    
    String prefix,instName;
    String? spiceModel,value,value2,spiceLine,spiceLine2;
}