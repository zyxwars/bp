## Utility for debugging signal flow
class_name SignalLogger extends RefCounted

func watch(target: Object) -> void:
    for s in target.get_signal_list():
        var signal_name: String = s["name"]
        var arg_count: int = (s["args"] as Array).size()
        var callable: Callable
        match arg_count:
            0: callable = func(): _log(signal_name, [])
            1: callable = func(a0): _log(signal_name, [a0])
            2: callable = func(a0, a1): _log(signal_name, [a0, a1])
            3: callable = func(a0, a1, a2): _log(signal_name, [a0, a1, a2])
            4: callable = func(a0, a1, a2, a3): _log(signal_name, [a0, a1, a2, a3])
            5: callable = func(a0, a1, a2, a3, a4): _log(signal_name, [a0, a1, a2, a3, a4])
            6: callable = func(a0, a1, a2, a3, a4, a5): _log(signal_name, [a0, a1, a2, a3, a4, a5])
            7: callable = func(a0, a1, a2, a3, a4, a5, a6): _log(signal_name, [a0, a1, a2, a3, a4, a5, a6])
            8: callable = func(a0, a1, a2, a3, a4, a5, a6, a7): _log(signal_name, [a0, a1, a2, a3, a4, a5, a6, a7])
            9: callable = func(a0, a1, a2, a3, a4, a5, a6, a7, a8): _log(signal_name, [a0, a1, a2, a3, a4, a5, a6, a7, a8])
            10: callable = func(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9): _log(signal_name, [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9])
            # Unbind omitted args
            _: callable = (func(): _log("%s (args omitted)" % signal_name, [])).unbind(arg_count)

        target.connect(signal_name, callable)

func _log(signal_name: String, args: Array) -> void:
    print("[Signal] %s(%s)" % [signal_name, ", ".join(args.map(func(a): return str(a)))])