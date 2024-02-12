import SwiftUI
import MapKit

struct ContentView: View {
    struct AnnotationItem: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
        let color: Color
        let severity: Int
    }
    
    struct AnimatedBackgroundView: View {
        
        @State private var currentColorSet = 0
        
        let colors1 = [Color(red: 0.8, green: 0.0, blue: 0.0), Color(red: 0.0, green: 0.0, blue: 0.0)]
        let colors2 = [Color(red: 0.0, green: 0.0, blue: 0.0), Color(red: 0.5, green: 0.0, blue: 0.8)]
        
        @State private var animateGradient = false
        
        var body: some View {
            let gradColors = [colors1, colors2][currentColorSet % 2]
            LinearGradient(gradient: Gradient(colors: gradColors), startPoint: .topLeading, endPoint: .bottomTrailing)
                .animation(Animation.easeInOut(duration: 8).repeatForever(autoreverses: true), value: currentColorSet)
                .onAppear {
                    withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                        self.currentColorSet += 1
                    }
                }
                .edgesIgnoringSafeArea(.all)
        }
    }
    
    struct SparkleView: View {
        let amtSparkles: Int = 75
        
        var body: some View {
            GeometryReader { geometry in
                ZStack {
                    ForEach(0..<amtSparkles, id: \.self) { _ in
                        Sparkle()
                            .position(x: CGFloat.random(in: 0...geometry.size.width),
                                      y: CGFloat.random(in: 0...geometry.size.height))
                    }
                }
            }
        }
        
        struct Sparkle: View {
            var body: some View {
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: CGFloat.random(in: 2...5), height: CGFloat.random(in: 2...5))
                    .shadow(color: .white, radius: 2)
            }
        }
    }
    
    @State var firstImportMade: Bool = false
    @State var importSuccess: Bool = true
    
    @State var initYear: Bool = false
    @State var initCSV: Bool = false
    @State var initInfo: Bool = false
    
    @State var fileNames: [String] = []
    
    @State private var isImporting = false
    @State private var filesLoaded = 0
    @State var fileNamingConv: Int = 1
    let maxFiles = 5
    
    @State var numberInput: String = ""
    @State var allAnnotations: [AnnotationItem] = []
    @State var annotationsCalculated: Bool = false
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), span: MKCoordinateSpan(latitudeDelta: 180, longitudeDelta: 360))
    @State private var annotationItems: [AnnotationItem] = []
    
    var body: some View {
        if initInfo {
            Map(coordinateRegion: $region, annotationItems: annotationItems) { item in
                MapAnnotation(coordinate: item.coordinate) {
                    let size = item.severity == 4 ? 10.0 : item.severity == 3 ? 8.0 : item.severity == 2 ? 6.0 : 4.0
                    Circle()
                        .fill(item.color)
                        .frame(width: size, height: size)
                }
            }
            ZStack {
                Spacer()
                VStack {
                    HStack { 
                        Text("Legend:")
                            .font(.system(size:20))
                            .foregroundStyle(Color.white)
                            .background(Color.clear)
                            .shadow(color: Color.white, radius: 5)
                            .padding(.bottom, 5)
                    }
                    HStack {
                        VStack {
                            ForEach(0..<self.filesLoaded, id: \.self) { i in
                                HStack {
                                    Text("\(self.fileNames[i])")
                                        .padding(.bottom, 3)
                                }
                                HStack {
                                    ForEach(1...4, id: \.self) { severity in
                                        Circle()
                                            .fill(self.getColor(dataSetNumber: i+1, severity: severity)) 
                                            .frame(width: 10, height: 10)
                                            .padding(.bottom, 10) 
                                }
                                }
                            }
                        }
                    }
                }
            }
            
            .onAppear {
                if !annotationsCalculated {
                    var allAnnotations: [AnnotationItem] = []
                    for dataSetNum in 1...5 {
                        let annotations = self.loadData(loadDataSetNum: dataSetNum, yearPeramLoadData: numberInput)
                        allAnnotations += annotations
                        }
                            self.annotationItems = allAnnotations
                            self.annotationsCalculated = true
                }
            }
        } else {
            
            ZStack {
                AnimatedBackgroundView()
                SparkleView()
                Spacer()
                VStack {
                    Text("\(filesLoaded)/\(maxFiles)")
                        .padding(10)
                    
                    if self.filesLoaded < self.maxFiles {
                        Button("Click to Import CSV") {
                            isImporting = true
                        }
                        .fileImporter(
                            isPresented: $isImporting,
                            allowedContentTypes: [.commaSeparatedText],
                            allowsMultipleSelection: false
                        ) { result in
                            switch result {
                            case .success(let urls):
                                let url = urls[0]
                                saveCSV(from: url)
                            case .failure:
                                print("Error selecting file")
                            }
                        }
                    }
                    
                    if importSuccess {
                        Text("CSV Files Loaded:")
                            .padding(10)
                    } else {
                        Text("CSV Files Loaded:")
                            .padding(10)
                        Text("File already slected?")
                            .font(.system(size:10))
                            .foregroundStyle(Color.red)
                    }
                    if self.filesLoaded > 0 {
                        ForEach(0..<self.filesLoaded, id: \.self) { index in
                            Text(self.fileNames[index])
                        }
                    }
                        
                }
                                
                Text("LayOver")
                    .font(.system(size: 80))
                    .italic()
                    .bold()
                    .shadow(color: .white, radius: 60)
                    .padding(.bottom, 600)
             
                VStack {
                    TextField("Year", text: $numberInput)
                        .padding(.horizontal, 190)
                        .padding(.vertical)
                        .onSubmit {
                            if Double(numberInput) != nil {
                                initYear = true
                            } else {
                                initYear = false
                            }
                        }
                        .textFieldStyle(.roundedBorder)
                    
                    HStack {
                        Text("Ready to initialize?")
                            .font(.system(size:25))
                            .foregroundStyle(Color.white)
                            .italic()
                        Button("[       X       ]") {
                            if fileNames.count != 0 && initYear {
                                initInfo = true
                            }
                        }
                        .padding()
                        .font(.system(size:25))
                        .foregroundColor(.white)
                        .shadow(color: .white, radius: 5)
                    }
                }
                .padding(.top, 700)
            }
            .edgesIgnoringSafeArea(.all)
        } 
    }
    
    func saveCSV(from url: URL) {
        
        let fileName = url.lastPathComponent
        
        if !self.fileNames.contains(fileName) {
            if !self.firstImportMade {
                self.firstImportMade.toggle()
            }
            
            fileNames.append(fileName)
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                saveToDirectory(content: content) //, fileName: url.lastPathComponent)
                filesLoaded += 1
                fileNamingConv += 1
                importSuccess = true
            } catch {
                print("saveCSV() error")
            }
        } else {
            importSuccess = false
            print("File already exists in directory")
        }
    }
    
    func saveToDirectory(content: String) {
        guard let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let newFileName: String = "\(fileNamingConv).csv" // Updated to use fileNamingConv and add .csv extension
        let fileUrl = documentDirectoryUrl.appendingPathComponent(newFileName)
        do {
            try content.write(to: fileUrl, atomically: true, encoding: .utf8)
        } catch {
        }
    }

    
    func loadData(loadDataSetNum: Int, yearPeramLoadData: String) -> [AnnotationItem] {
        var coords = loadCoordinates(coordinateFileName: "coord")
        let offset = getOffSet(dataSetNumber: loadDataSetNum)
        
        coords = coords.map { coord in
            let adjustedLatitude = coord.1 + offset.0
            let adjustedLongitude = coord.2 + offset.1
            return (coord.0, adjustedLatitude, adjustedLongitude)
        }
//        print("")
//        print(loadDataSetNum)
//        print("")
        let dataSet = averageProcessedCSV(dataSet: loadCSVData(numSet: loadDataSetNum, yearPeram: yearPeramLoadData))

        let processedData = coordSeverityColor(coords: coords, dataSet: dataSet, dataSetNum: loadDataSetNum)
        
        return processedData.map { data in
            AnnotationItem(coordinate: CLLocationCoordinate2D(latitude: data.1, longitude: data.2), color: data.3, severity: data.4)
        }
    }
    
    func coordSeverityColor(coords: [(String, Double, Double)], dataSet: [(String, Int, Double, Int)], dataSetNum: Int) -> [(Int, Double, Double, Color, Int)] {
        // returns severity attached to coordinates
        let offSet = getOffSet(dataSetNumber: dataSetNum)
        var finalAry: [(Int, Double, Double, Color, Int)] = []
        
        for dataLine in dataSet {
            for coordPair in coords {
                if dataLine.0 == coordPair.0 {
                    finalAry.append((dataLine.3, coordPair.1 + offSet.0, coordPair.2 + offSet.1, getColor(dataSetNumber: dataSetNum, severity: dataLine.3), dataLine.3))
                }
            }
        }
        return finalAry
    }
    
    func getColor(dataSetNumber: Int, severity: Int) -> Color {
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        
        switch dataSetNumber {
        case 1:
            green = 0
            blue = 0
            switch severity {
            case 1:
                red = 0.25
            case 2:
                red = 0.5
            case 3:
                red = 0.75
            case 4:
                red = 1.0
            default:
                break
            }
        case 2:
            green = 0
            red = 0
            switch severity {
            case 1:
                blue = 0.25
            case 2:
                blue = 0.5
            case 3:
                blue = 0.75
            case 4:
                blue = 1.0
            default:
                break
            }
        case 3:
            green = 0
            blue = 0
            switch severity {
            case 1:
                green = 0.25
            case 2:
                green = 0.5
            case 3:
                green = 0.75
            case 4:
                green = 1.0
            default:
                break
            }
        case 4:
            green = 0
            blue = 0.5
            switch severity {
            case 1:
                red = 0.25
            case 2:
                red = 0.5
            case 3:
                red = 0.75
            case 4:
                red = 1.0
            default:
                break
            }
        case 5:
            switch severity {
            case 1:
                green = 0.25
                red = 0.25
                blue = 0.25
            case 2:
                green = 0.5
                red = 0.5
                blue = 0.5
            case 3:
                green = 0.75
                red = 0.75
                blue = 0.75
            case 4:
                green = 1.0
                red = 1.0
                blue = 1.0
            default:
                break
            }
        default:
            break 
        }
        return Color(red: red, green: green, blue: blue)
    }
    
    func getOffSet(dataSetNumber: Int) -> (Double, Double) {
        var offSet: (Double, Double)
        
        switch dataSetNumber {
        case 1:
            offSet = (0.5, 0)
        case 2:
            offSet = (0.5*cos(2 * Double.pi / 5), 0.5*sin(2 * Double.pi / 5))
        case 3:
            offSet = (0.5*cos(4 * Double.pi / 5), 0.5*sin(4 * Double.pi / 5))
        case 4:
            offSet = (0.5*cos(6 * Double.pi / 5), 0.5*sin(6 * Double.pi / 5))
        case 5:
            offSet = (0.5*cos(8 * Double.pi / 5), 0.5*sin(8 * Double.pi / 5))
        default:
            offSet = (0, 0)
        }
        return offSet
    }

    func loadCoordinates(coordinateFileName: String) -> [(String, Double, Double)] {
        
        var coords: [(String, Double, Double)] = []
        
        guard let coordFileURL = Bundle.main.url(forResource: coordinateFileName, withExtension: "csv") else {
            print("CSV file not found")
            return []
        }
        
        do {
            let content = try String(contentsOf: coordFileURL)
            let rows = content.components(separatedBy: "\n")
            
            // skip the header
            for i in 1..<rows.count {
                let row = rows[i]
                let columns = row.components(separatedBy: ",")
                
                if columns.count >= 6 {
                    let country = columns[2]
                    
                    // latitude
                    var latitude = columns[4]
                    var newLat: Double = 0
                    
                    if latitude.contains("-") {
                        latitude = latitude.replacingOccurrences(of: "-", with: "")
                        newLat = -Double(latitude)!
                    } else {
                        newLat = Double(latitude)!
                    }
                    
                    // longitude
                    var longitude = columns[5]
                    var newLong: Double = 0
                    
                    if longitude.contains("-") {
                        longitude = longitude.replacingOccurrences(of: "-", with: "")
                         newLong = -Double(longitude)!
                    } else {
                        newLong = Double(longitude)!
                    }
                    
                    let rowData: (String, Double, Double) = (country, newLat, newLong)
                    coords.append(rowData)
                }
            }
        } catch {
            print("Failed to load coordinate file")
        }
        return coords
    }
    
    
    func loadCSVData(numSet: Int, yearPeram: String) -> [(String, Int, Double, Int)] {
        var altDataSet: [(String, Int, Double, Int)] = []
        
        // let forResourcePeram: String = String(numSet)
        guard let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Document directory not found")
            return []
        }
        let csvFileName = "\(numSet).csv"
        let csvFileURL = documentDirectoryUrl.appendingPathComponent(csvFileName)
        do {
            let content = try String(contentsOf: csvFileURL, encoding: .utf8)
            let rows = content.components(separatedBy: "\n")
            
            for row in rows {
                let columns = row.components(separatedBy: ",")
                if columns.count >= 3 {
                    let country = columns[1]
                    let year = columns[2]
                    let val = columns[3]
                    
                    if ((year == yearPeram) && (country != "")) {
                        let rowData = (country, Int(year)!, Double(val)!, 0)
                        altDataSet.append(rowData)
                    }
                }
            }
        } catch {
            print("Error reading CSV file")
        }
        
        return altDataSet
    }
    
    
//    func averageProcessedCSV(dataSet: [(String, Int, Double, Int)]) -> [(String, Int, Double, Int)] {
//        var processedDataSet = dataSet
//        
//        let total = processedDataSet.reduce(0.0) { $0 + $1.2 }
//        let mean = total / Double(processedDataSet.count)
//        
//        let variance = processedDataSet.reduce(0.0) { $0 + pow($1.2 - mean, 2) } / Double(processedDataSet.count)
//        let standardDeviation = sqrt(variance)
//        
//        for (index, data) in processedDataSet.enumerated() {
//            let deviationFromMean = data.2 - mean
//            
//            switch deviationFromMean {
//            case ..<(-standardDeviation):
//                processedDataSet[index].3 = 1
//            case -standardDeviation...standardDeviation:
//                processedDataSet[index].3 = 2
//            case standardDeviation...:
//                processedDataSet[index].3 = 3
//            default:
//                processedDataSet[index].3 = 4
//            }
//        }
//        
//        return processedDataSet
//    }
    
    func averageProcessedCSV(dataSet: [(String, Int, Double, Int)]) -> [(String, Int, Double, Int)] {
        
        var altDataSet: [(String, Int, Double, Int)] = dataSet
        
        // Tracking
        var numVal: Double = 0
        var totalVal: Double = 0
        
        for triplet in altDataSet {
            numVal += 1
            totalVal += triplet.2
        }
        
        let quartile2: Double = totalVal / numVal
        let quartile1: Double = quartile2 / 2.0
        let quartile3: Double = quartile2 + quartile1
        
        var iterator: Int = 0
        
        for triplet in dataSet {
            if triplet.2 <= quartile1 {
                altDataSet[iterator].3 = 1
            } else if triplet.2 <= quartile2 {
                altDataSet[iterator].3 = 2
            } else if triplet.2 <= quartile3 {
                altDataSet[iterator].3 = 3
            } else {
                altDataSet[iterator].3 = 4
            }
            iterator += 1
        }
        return altDataSet
    }


}
