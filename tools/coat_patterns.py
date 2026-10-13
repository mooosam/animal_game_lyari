"""Asymmetric world-coordinate patterns baked into each mesh's unique UVs."""
def patterned_coat(nodes,links,paint,bsdf,key,width,front,rear,height):
    coord=nodes.new('ShaderNodeTexCoord')
    def mathnode(op,a,b=None):
        n=nodes.new('ShaderNodeMath'); n.operation=op
        if hasattr(a,'is_output'): links.new(a,n.inputs[0])
        else: n.inputs[0].default_value=a
        if b is not None:
            if hasattr(b,'is_output'): links.new(b,n.inputs[1])
            else: n.inputs[1].default_value=b
        return n.outputs[0]
    fac=None; target=(.015,.012,.009,1)
    if key in ['cheetah','giraffe','snow_leopard','harbour_seal']:
        v=nodes.new('ShaderNodeTexVoronoi'); links.new(coord.outputs['Object'],v.inputs['Vector'])
        v.inputs['Scale'].default_value={'cheetah':12,'giraffe':5.5,'snow_leopard':9,'harbour_seal':9}[key]
        if key=='giraffe':
            v.feature='DISTANCE_TO_EDGE'; fac=mathnode('GREATER_THAN',v.outputs['Distance'],.07); target=(.23,.075,.019,1)
        elif key=='snow_leopard':
            fac=mathnode('MULTIPLY',mathnode('GREATER_THAN',v.outputs['Distance'],.15),mathnode('LESS_THAN',v.outputs['Distance'],.25))
        else: fac=mathnode('LESS_THAN',v.outputs['Distance'],.20 if key=='cheetah' else .24)
    if key in ['tiger','zebra','red_panda','raccoon']:
        v=nodes.new('ShaderNodeTexWave'); v.bands_direction='Y'; links.new(coord.outputs['Object'],v.inputs['Vector']); v.inputs['Scale'].default_value=4 if key=='tiger' else 8; v.inputs['Distortion'].default_value=5; v.inputs['Detail'].default_value=3
        fac=mathnode('GREATER_THAN',v.outputs['Fac'],.64)
        if key in ['red_panda','raccoon']:
            sep=nodes.new('ShaderNodeSeparateXYZ'); links.new(coord.outputs['Object'],sep.inputs[0]); fac=mathnode('MULTIPLY',fac,mathnode('GREATER_THAN',sep.outputs['Y'],rear*.35))
    if fac is not None:
        mix=nodes.new('ShaderNodeMixRGB'); links.new(fac,mix.inputs[0]); links.new(paint.outputs['Color'],mix.inputs[1]); mix.inputs[2].default_value=target
        coat=mix.outputs[0]
    else: coat=paint.outputs['Color']
    if key=='cheetah':
        sep=nodes.new('ShaderNodeSeparateXYZ'); links.new(coord.outputs['Object'],sep.inputs[0]); ax=mathnode('ABSOLUTE',sep.outputs['X'])
        mark=mathnode('MULTIPLY',mathnode('GREATER_THAN',ax,width*.13),mathnode('LESS_THAN',ax,width*.27))
        mark=mathnode('MULTIPLY',mark,mathnode('LESS_THAN',sep.outputs['Y'],-front*.65))
        mark=mathnode('MULTIPLY',mark,mathnode('GREATER_THAN',sep.outputs['Z'],height*.46))
        mix=nodes.new('ShaderNodeMixRGB'); links.new(mark,mix.inputs[0]); links.new(coat,mix.inputs[1]); mix.inputs[2].default_value=(.01,.007,.004,1); coat=mix.outputs[0]
    links.new(coat,bsdf.inputs['Base Color'])
    return coord
