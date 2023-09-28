//
//  ContentView.swift
//  todo-ios
//
//  Created by Alwan Wirawan on 28/09/23.
//
import SwiftUI

struct ContentView: View {
    @State private var tasks: [Task] = []
    @State private var newTask = ""

    var body: some View {
        NavigationView {
            VStack {
                TextField("Add a new task", text: $newTask)
                    .padding()
                Button(action: addTask) {
                    Text("Add Task")
                }
                List {
                    ForEach(tasks) { task in
                        TaskRowView(task: task, toggleTask: toggleTask)
                    }
                }
            }
            .navigationTitle("To-Do List")
        }
        .onAppear(perform: fetchTasks)
    }

    func fetchTasks() {
        guard let url = URL(string: "http://127.0.0.1:8080/get-todo") else { return }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                if let tasks = try? JSONDecoder().decode([Task].self, from: data) {
                    DispatchQueue.main.async {
                        self.tasks = tasks
                    }
                }
            }
        }.resume()
    }

    func addTask() {
        guard let url = URL(string: "http://127.0.0.1:8080/add-todo") else { return }
        guard let postData = try? JSONEncoder().encode(["task": newTask]) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = postData
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle the response from the server
            fetchTasks()
        }.resume()
        
        newTask = ""
    }
    
    func toggleTask(taskIn: Task) {
        guard let index = tasks.firstIndex(where: { $0.id == taskIn.id }) else {
             return
        }

        tasks[index].completed.toggle()

        var task = Task(id: taskIn.id, task: taskIn.task, completed: taskIn.completed)
        
        task.completed = task.completed == true ? false : true
        
        guard let url = URL(string: "http://127.0.0.1:8080/update-todo") else { return }
        guard let postData = try? JSONEncoder().encode(task) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = postData
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle the response from the server
        }.resume()
     }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct TaskRowView: View {
    let task: Task
    let toggleTask: (Task) -> Void

    var body: some View {
        HStack {
            Button(action: { toggleTask(task) }) {
                Image(systemName: task.completed ? "checkmark.square.fill" : "square")
            }
            .buttonStyle(BorderlessButtonStyle())
            Text(task.task)
                .strikethrough(task.completed)
            Spacer()
        }
    }
}

struct Task: Identifiable, Encodable, Decodable {
    var id: Int
    var task: String
    var completed: Bool
}
