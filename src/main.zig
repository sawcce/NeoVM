const std = @import("std");

const Heap = []*anyopaque;
const HeapItem = u64;
const Instruction = *const fn (*VM) anyerror!void;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const Builder = struct {
    heap: std.ArrayList(HeapItem),
    constants: std.ArrayList(HeapItem),
    instructions: std.ArrayList(*const fn (*VM) anyerror!void),

    const Self = @This();

    pub fn new() @This() {
        const heap = std.ArrayList(HeapItem).init(allocator);
        const constants = std.ArrayList(HeapItem).init(allocator);
        const instructions = std.ArrayList(*const fn (*VM) anyerror!void).init(allocator);

        return @This(){ .heap = heap, .constants = constants, .instructions = instructions };
    }

    pub fn add(self: *Self, a: HeapItem, b: HeapItem) !void {
        try self.heap.append(a);
        try self.heap.append(b);
        try self.instructions.append(&VM.add);
    }

    pub fn substract(self: *Self, a: HeapItem, b: HeapItem) !void {
        try self.heap.append(a);
        try self.heap.append(b);
        try self.instructions.append(&VM.substract);
    }

    pub fn jump(self: *Self, pos: HeapItem) !void {
        try self.heap.append(pos);
        try self.instructions.append(&VM.jump);
    } 

    pub fn jnz(self: *Self, pos: HeapItem) !void {
        try self.heap.append(pos);
        try self.instructions.append(&VM.jnz);
    } 

    pub fn popSay(self: *Self) !void {
        try self.instructions.append(&VM.popSay);
    }

    pub fn setA(self: *Self) !void {
        try self.instructions.append(&VM.setA);
    }

    pub fn pushA(self: *Self) !void {
        try self.instructions.append(&VM.pushA);
    }

    pub fn setB(self: *Self) !void {
        try self.instructions.append(&VM.setB);
    }

    pub fn pushB(self: *Self) !void {
        try self.instructions.append(&VM.pushB);
    }

    pub fn dbg(self: *Self) !void {
        try self.instructions.append(&VM.dbg);
    }
};

const VM = struct {
    heap: std.ArrayList(HeapItem),
    constants: std.ArrayList(HeapItem),
    ip: usize = 0,
    instructions: std.ArrayList(*const fn (*VM) anyerror!void),
    regA: HeapItem = 0,
    regB: HeapItem = 0,

    pub fn new() @This() {
        const heap = std.ArrayList(HeapItem).init(allocator);
        const constants = std.ArrayList(HeapItem).init(allocator);
        const instructions = std.ArrayList(*const fn (*VM) anyerror!void).init(allocator);

        return @This(){ .heap = heap, .constants = constants, .instructions = instructions };
    }

    pub fn fromBuilder(builder: Builder) @This() {
        return @This(){ .ip = 0, .heap = builder.heap, .constants = builder.constants, .instructions = builder.instructions };
    }

    pub fn deinit(self: *@This()) void {
        self.heap.deinit();
    }

    pub fn push(self: *@This(), value: HeapItem) !void {
        try self.heap.append(value);
    }

    pub fn peek(self: *const @This()) HeapItem {
        return self.heap.getLast();
    }

    pub fn peekBy(self: *const @This(), amount: usize) HeapItem {
        return self.heap.items[self.heap.items.len - amount];
    }

    pub fn add(self: *@This()) anyerror!void {
        const first = self.pop();
        const last = self.pop();
        try self.push(first + last);
    }

    pub fn substract(self: *@This()) anyerror!void {
        const first = self.pop();
        const last = self.pop();
        std.log.info("{} - {}", .{last, first});
        try self.push(last - first);
    }

    pub fn jump(self: *@This()) anyerror!void {
        self.ip = @intCast(usize, self.pop() - 1);
    }

    pub fn jnz(self: *@This()) anyerror!void {
        std.log.info("Last value: {}", .{self.peekBy(2) });
        if(self.peekBy(2) != 0) {
            try self.jump();
        }
        std.log.info("Didn't jump: IP: {}", .{self.ip});
    }

    pub fn popSay(self: *@This()) anyerror!void {
        std.log.info("Items: {any}", .{self.heap.items});
        std.log.info("Last item: {}", .{self.pop()});
    }

    pub fn pop(self: *@This()) HeapItem {
        return self.heap.pop();
    }

    pub fn pushConstant(self: *@This()) !void {
        try self.push(self.constants.items[self.pop()]);
    }

    pub fn setA(self: *VM) !void {
        self.regA = self.pop();
    }

    pub fn pushA(self: *VM) !void {
        try self.push(self.regA);
    }

    pub fn setB(self: *VM) !void {
        self.regB = self.pop();
    }

    pub fn pushB(self: *VM) !void {
        try self.push(self.regB);
    }

    pub fn dbg(self: *const VM) anyerror!void {
        return std.log.info("DBG: {any}; A: {}; B: {}", .{self.heap.items, self.regA, self.regB});
    }

    pub fn execute(self: *@This()) !void {
        while (self.ip < self.instructions.items.len) : (self.ip += 1) {
            var instruction = self.instructions.items[self.ip];
            std.log.info("Instruction: {s}", .{"sdfdf"});
            try instruction(self);
        }
    }
};

pub fn main() !void {
    //var vm = VM.new();
    //
    //try vm.constants.append(17);
    //
    //try vm.push(8);
    //try vm.push(16);
    //try vm.push(0);
    //
    //std.log.info("VM: {any}", .{vm.heap.items});
    //
    //var instructions = [_]*const fn (*VM) anyerror!void{
    //    &VM.pushConstant,
    //    &VM.add,
    //    &VM.dbg,
    //    &VM.add,
    //    &VM.dbg,
    //};
    //try vm.execute();
    //vm.deinit();

    var builder = Builder.new();
    try builder.heap.append(10);


    try builder.setB();
    try builder.setA();

    try builder.heap.append(1);
    try builder.heap.append(2);

    try builder.dbg();
    try builder.pushA();

    try builder.dbg();
    try builder.instructions.append(&VM.substract);
    try builder.pushB();
    try builder.instructions.append(&VM.jnz);


    var vm = VM.fromBuilder(builder);
    try vm.execute();
    defer vm.deinit();
}
