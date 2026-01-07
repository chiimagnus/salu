/// 输入读取器
/// 用于在测试中注入自定义输入流
enum InputReader {
    static nonisolated(unsafe) var readLine: () -> String? = {
        Swift.readLine()
    }
}
