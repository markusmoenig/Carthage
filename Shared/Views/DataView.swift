//
//  DataView.swift
//  Carthage
//
//  Created by Markus Moenig on 12/7/21.
//

import SwiftUI

/// DataFloatSliderView
struct DataFloatSliderView: View {
    
    let model                               : CarthageModel
    let groupName                           : String

    var value                               : Binding<Float>
    var valueText                           : Binding<String>
    var range                               : Binding<float2>

    var factor                              : CGFloat = 1

    @State var clipWidth                    : CGFloat = 0
    
    @State var color                        : Color

    init(_ model: CarthageModel,_ name : String,_ value :Binding<Float>,_ valueText :Binding<String>,_ range: Binding<float2>,_ color: Color = Color.accentColor,_ factor: CGFloat = 1)
    {
        self.model = model
        self.groupName = name
        self.value = value
        self.valueText = valueText
        self.range = range
        self.color = color
        self.factor = factor
        
        //valueText.wrappedValue = String(format: "%.02f", value.wrappedValue)
    }

    var body: some View {
            
        GeometryReader { geom in
            Canvas { context, size in
                context.fill(
                    Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 8),
                    with: .color(.gray))
                
                var maskedContext = context

                maskedContext.clip(
                    to: Path(roundedRect: CGRect(origin: .zero, size: CGSize(width: getClipWidth(size.width), height: size.height)), cornerRadius: 0))
                
                maskedContext.fill(
                    Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 8),
                    with: .color(color))

                context.draw(Text(valueText.wrappedValue), at: CGPoint(x: geom.size.width / 2, y: geom.size.height / factor), anchor: .center)
                
            }
            .frame(width: geom.size.width, height: 19)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                
                    .onChanged({ info in
                        
                        let offset = Float(info.location.x / geom.size.width)
                
                        let r = range.wrappedValue
                
                        var newValue = r.x + (r.y - r.x) * offset
                        newValue = max(newValue, r.x)
                        newValue = min(newValue, r.y)
                    
                        value.wrappedValue = newValue
                        valueText.wrappedValue = String(format: "%.02f",  newValue)
                        
                        model.updateSelectedGroup(groupName: groupName)
                    })
                    .onEnded({ info in
                    })
            )
        }
        
        //.onReceive(model.updateDataViews) { _ in
        //    valueText = String(format: "%.02f", value.wrappedValue)
        //}
    }
    
    func getClipWidth(_ width: CGFloat) -> CGFloat {
        let v = value.wrappedValue
        let r = range.wrappedValue

        let off = CGFloat((v - r.x) / (r.y - r.x))
        return off * width
    }
}

/// The view of a single DataEntity
struct DataEntityView: View {
    
    let model                               : CarthageModel
    let groupName                           : String
    let entity                              : CarthageDataEntity
    
    // For Sliders
    @State var xValue                       : Float = 0
    @State var yValue                       : Float = 0
    @State var zValue                       : Float = 0
    @State var valueRange                   = float2()
    
    // For Numeric
    @State private var xText                : String
    @State private var yText                : String
    @State private var zText                : String
    
    // For Color
    @State private var colorValue           = Color.white
    
    // For Texture Feature
    @State private var showTexturePopup     = false

    // To Lock Values
    @State var isLocked                     = false

    // To Reference Library Assets (Texture Feature)
    @State private var libraryName          = ""

    init(_ model: CarthageModel,_ name: String,_ entity: CarthageDataEntity) {
        self.model = model
        self.entity = entity
        self.groupName = name
        
        _xValue = State(initialValue: entity.value.x)
        _yValue = State(initialValue: entity.value.y)
        _zValue = State(initialValue: entity.value.z)
        _valueRange = State(initialValue: entity.range)
        
        _xText = State(initialValue: String(format: "%.02f", entity.value.x))
        _yText = State(initialValue: String(format: "%.02f", entity.value.y))
        _zText = State(initialValue: String(format: "%.02f", entity.value.z))
        
        _colorValue = State(initialValue: Color(red: Double(entity.value.x), green: Double(entity.value.y), blue: Double(entity.value.z)))
        
        _libraryName = State(initialValue: entity.text)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(entity.key)
                Spacer()
                if (entity.usage == .Slider || entity.usage == .Numeric) && entity.type != .Float {
                    Button(action: {
                        isLocked.toggle()
                    })
                    {
                        Image(systemName: isLocked ? "link.circle.fill" : "link.circle")
                    }
                    .buttonStyle(.borderless)
                } else
                if entity.feature == .Texture {
                    Button(action: {
                        showTexturePopup = true
                    })
                    {
                        Image(systemName: entity.text.isEmpty ? "photo" : "photo.fill")
                    }
                    .buttonStyle(.borderless)
                }

                Button(action: {
                    // RESET
                    entity.value = entity.defaultValue
                    entity.text = ""
                    if entity.usage == .Slider {
                        xValue = entity.value.x
                        yValue = entity.value.y
                        zValue = entity.value.z
                        
                        xText = String(format: "%.02f", entity.value.x)
                        yText = String(format: "%.02f", entity.value.y)
                        zText = String(format: "%.02f", entity.value.z)
                    } else
                    if entity.usage == .Numeric {
                        xText = String(format: "%.02f", entity.value.x)
                        yText = String(format: "%.02f", entity.value.y)
                        zText = String(format: "%.02f", entity.value.z)
                    } else
                    if entity.usage == .Color {
                        colorValue = Color(red: Double(entity.value.x), green: Double(entity.value.y), blue: Double(entity.value.z))
                    }
                    model.updateSelectedGroup(groupName: groupName)
                })
                {
                    Image(systemName: "x.circle")
                }
                .buttonStyle(.borderless)
            }
            HStack {
                if entity.usage == .Slider {
                    HStack {
                        DataFloatSliderView(model, groupName, $xValue, $xText, $valueRange, .red)
                        if entity.type == .Float2 || entity.type == .Float3 {
                            DataFloatSliderView(model, groupName, $yValue, $yText, $valueRange, .green)
                        }
                        if entity.type == .Float3 {
                            DataFloatSliderView(model, groupName, $zValue, $zText, $valueRange, .blue)
                        }
                    }
                } else
                if entity.usage == .Color {
                    ColorPicker("", selection: $colorValue, supportsOpacity: false)
                    Spacer()
                        .onChange(of: colorValue) { newValue in
                            if let cgColor = newValue.cgColor {

                                entity.value.x = Float(cgColor.components![0])
                                entity.value.y = Float(cgColor.components![1])
                                entity.value.z = Float(cgColor.components![2])

                                model.updateSelectedGroup(groupName: groupName)
                            }
                        }
                } else
                if entity.usage == .Numeric {
                    TextField("", text: $xText, onEditingChanged: { changed in
                        if let v = Float(xText) {
                            entity.value.x = v
                            if isLocked {
                                entity.value.y = v
                                entity.value.z = v
                                yText = String(format: "%.02f", entity.value.y)
                                zText = String(format: "%.02f", entity.value.z)
                            }
                            model.updateSelectedGroup(groupName: groupName)
                        }
                    })
                        .border(.red)
                    
                    if entity.type == .Float2 || entity.type == .Float3 {
                        TextField("", text: $yText, onEditingChanged: { changed in
                            if let v = Float(yText) {
                                entity.value.y = v
                                if isLocked {
                                    entity.value.x = v
                                    entity.value.z = v
                                    xText = String(format: "%.02f", entity.value.x)
                                    zText = String(format: "%.02f", entity.value.z)
                                }
                                model.updateSelectedGroup(groupName: groupName)
                            }
                        })
                            .border(.green)
                    }
                    
                    if entity.type == .Float3 {
                        TextField("", text: $zText, onEditingChanged: { changed in
                            if let v = Float(zText) {
                                entity.value.z = v
                                if isLocked {
                                    entity.value.x = v
                                    entity.value.y = v
                                    xText = String(format: "%.02f", entity.value.x)
                                    yText = String(format: "%.02f", entity.value.y)
                                }
                                model.updateSelectedGroup(groupName: groupName)
                            }
                        })
                            .border(.blue)
                    }
                }
            }
        }
        
        // Texture feature
        .popover(isPresented: self.$showTexturePopup,
                 arrowEdge: .bottom
        ) {
            VStack(alignment: .leading) {
                Text("Library Name")
                    .foregroundColor(Color.secondary)
                TextField("Name", text: $libraryName, onEditingChanged: { (changed) in
                    entity.text = libraryName
                    model.updateSelectedGroup(groupName: groupName)
                })
                .frame(minWidth: 300)
            }.padding()
        }
        
        // Slider values changed
        
        .onChange(of: xValue) { value in
            entity.value.x = value
            if isLocked {
                entity.value.y = value
                entity.value.z = value
                yValue = value
                zValue = value
                yText = String(format: "%.02f", entity.value.y)
                zText = String(format: "%.02f", entity.value.z)
            }
            model.updateSelectedGroup(groupName: groupName)
        }
        
        .onChange(of: yValue) { value in
            entity.value.y = value
            if isLocked {
                entity.value.x = value
                entity.value.z = value
                xValue = value
                zValue = value
                xText = String(format: "%.02f", entity.value.x)
                zText = String(format: "%.02f", entity.value.z)
            }
            model.updateSelectedGroup(groupName: groupName)
        }
        
        .onChange(of: zValue) { value in
            entity.value.z = value
            if isLocked {
                entity.value.x = value
                entity.value.y = value
                xValue = value
                yValue = value
                xText = String(format: "%.02f", entity.value.x)
                yText = String(format: "%.02f", entity.value.y)
            }
            model.updateSelectedGroup(groupName: groupName)
        }
        
        //.onReceive(model.updateDataViews) { _ in
        //    xText = String(format: "%.02f", entity.value.x)
        //    yText = String(format: "%.02f", entity.value.y)
        //    zText = String(format: "%.02f", entity.value.z)
        //}
    }
}


struct DataView: View {
    
    let model                               : CarthageModel
    let name                                : String
    let data                                : CarthageData
    
    @State var updateView                   : Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                
                ForEach(data.data, id: \.id) { entity in
                    DataEntityView(model, name, entity)
                        .padding(2)
                        .padding(.leading, 6)
                        .padding(.trailing, 6)
                }
            }
        }
    }
}
