pragma solidity ^0.4.25;
// 必须开启此实验性特性，才能在函数中返回结构体数组（Todo[]）
pragma experimental ABIEncoderV2; 

contract TodoList {
    // 定义结构体
    struct Todo {
        string text;
        bool completed;
    }

    // 状态变量：存储所有任务
    Todo[] public todos;

    // 创建任务
    function create(string _text) public {
        todos.push(Todo(_text, false));
    }

    // 修改任务状态
    function toggleCompleted(uint256 _index) public {
        require(_index < todos.length, "Index out of bounds");
        Todo storage todo = todos[_index]; 
        todo.completed = !todo.completed;
    }

    // 修改任务内容
    function updateText(uint256 _index, string _text) public {
        require(_index < todos.length, "Index out of bounds");
        Todo storage todo = todos[_index];
        todo.text = _text;
    }

    // 获取单个任务
    function get(uint256 _index) public view returns (string, bool) {
        require(_index < todos.length, "Index out of bounds");
        Todo memory todo = todos[_index];
        return (todo.text, todo.completed);
    }

    // 【新增】获取所有任务
    // 依赖头部 pragma experimental ABIEncoderV2
    function getAll() public view returns (Todo[] memory) {
        return todos;
    }
    
    // 【可选】获取任务总数（方便前端遍历）
    function getCount() public view returns (uint256) {
        return todos.length;
    }
}