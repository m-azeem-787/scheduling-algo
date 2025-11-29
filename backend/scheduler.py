
from flask import Flask, request, jsonify

app = Flask(__name__)


# FIRST COME FIRST SERVE (FCFS) ALGORITHM
def fcfs(processes):
    # Sort by arrival time
    procs = sorted(processes, key=lambda x: x['at'])
    
    time = 0
    gantt = []
    results = []
    
    for p in procs:
        # Handle CPU idle time
        if time < p['at']:
            gantt.append({'id': 'Idle', 'start': time, 'end': p['at'], 'idle': True})
            time = p['at']
        
        # Execute process
        start = time
        end = time + p['bt']
        ct = end                    # Completion Time
        tat = ct - p['at']          # Turnaround Time = CT - AT
        wt = tat - p['bt']          # Waiting Time = TAT - BT
        rt = start - p['at']        # Response Time = Start - AT
        
        gantt.append({'id': p['id'], 'start': start, 'end': end, 'idx': p['idx']})
        results.append({
            'id': p['id'], 'at': p['at'], 'bt': p['bt'],
            'ct': ct, 'tat': tat, 'wt': wt, 'rt': rt, 'idx': p['idx']
        })
        time = end
    
    # Sort results by original index for display
    results.sort(key=lambda x: x['idx'])
    return results, gantt, time



# ROUND ROBIN (RR)
def round_robin(processes, quantum):
    # Create process list with remaining time tracking
    procs = []
    for p in sorted(processes, key=lambda x: x['at']):
        procs.append({
            'id': p['id'], 'at': p['at'], 'bt': p['bt'],
            'remaining': p['bt'], 'first_run': -1, 'idx': p['idx']
        })
    
    time = 0
    completed = 0
    n = len(procs)
    i = 0  # Index for tracking arrivals
    gantt = []
    queue = []
    
    # Add initial processes (arrived at time 0)
    while i < n and procs[i]['at'] <= time:
        queue.append(procs[i])
        i += 1
    
    # Main scheduling loop
    while completed < n:
        # Handle empty queue (CPU idle)
        if not queue:
            if i < n:
                gantt.append({'id': 'Idle', 'start': time, 'end': procs[i]['at'], 'idle': True})
                time = procs[i]['at']
                while i < n and procs[i]['at'] <= time:
                    queue.append(procs[i])
                    i += 1
            continue
        
        # Get next process from queue
        curr = queue.pop(0)
        
        # Record first response time
        if curr['first_run'] == -1:
            curr['first_run'] = time
            curr['rt'] = time - curr['at']
        
        # Execute for quantum or remaining time (whichever is smaller)
        exec_time = min(curr['remaining'], quantum)
        start = time
        end = time + exec_time
        
        gantt.append({'id': curr['id'], 'start': start, 'end': end, 'idx': curr['idx']})
        curr['remaining'] -= exec_time
        time = end
        
        # Add newly arrived processes to queue
        while i < n and procs[i]['at'] <= time:
            queue.append(procs[i])
            i += 1
        
        # Check if process completed
        if curr['remaining'] > 0:
            queue.append(curr)  # Put back in queue
        else:
            completed += 1
            curr['ct'] = time
            curr['tat'] = curr['ct'] - curr['at']
            curr['wt'] = curr['tat'] - curr['bt']
    
    # Build results list
    results = []
    for p in procs:
        results.append({
            'id': p['id'], 'at': p['at'], 'bt': p['bt'],
            'ct': p['ct'], 'tat': p['tat'], 'wt': p['wt'], 'rt': p['rt'], 'idx': p['idx']
        })
    
    results.sort(key=lambda x: x['idx'])
    return results, gantt, time


# Calculate average
def calc_avg(results):
    n = len(results)
    return {
        'avg_tat': round(sum(r['tat'] for r in results) / n, 2),
        'avg_wt': round(sum(r['wt'] for r in results) / n, 2),
        'avg_rt': round(sum(r['rt'] for r in results) / n, 2)
    }


# API ENDPOINT
@app.route('/calculate', methods=['POST', 'OPTIONS'])
def calculate():
    # Handle CORS preflight request
    if request.method == 'OPTIONS':
        response = jsonify({})
        response.headers.add('Access-Control-Allow-Origin', '*')
        response.headers.add('Access-Control-Allow-Headers', 'Content-Type')
        response.headers.add('Access-Control-Allow-Methods', 'POST')
        return response
    
    data = request.json
    
    # Add index to each process
    processes = []
    for i, p in enumerate(data.get('processes', [])):
        processes.append({'id': p['id'], 'at': p['at'], 'bt': p['bt'], 'idx': i})
    
    quantum = data.get('quantum', 2)
    
    if not processes:
        return jsonify({'error': 'No processes provided'}), 400
    
    # Run both algorithms
    fcfs_res, fcfs_gantt, fcfs_time = fcfs(processes)
    rr_res, rr_gantt, rr_time = round_robin(processes, quantum)
    
    # Build response
    response = jsonify({
        'fcfs': {
            'results': fcfs_res,
            'gantt': fcfs_gantt,
            'metrics': calc_avg(fcfs_res),
            'total': fcfs_time
        },
        'rr': {
            'results': rr_res,
            'gantt': rr_gantt,
            'metrics': calc_avg(rr_res),
            'total': rr_time
        }
    })
    
    # Add CORS header to response
    response.headers.add('Access-Control-Allow-Origin', '*')
    return response


# RUN SERVER
if __name__ == '__main__':
    print("=" * 50)
    print("CPU Scheduling API Server")
    print("Running at: http://localhost:5000")
    print("=" * 50)
    app.run(debug=True, port=5000)