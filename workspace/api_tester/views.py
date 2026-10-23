from django.shortcuts import render

# Create your views here.

import json
import requests
from django.shortcuts import render

def api_tester_view(request):
    return render(request, "api_tester/index.html")

def test_api(request):
    if request.method == "POST":
        url = request.POST.get("url")
        method = request.POST.get("method", "GET")
        headers_str = request.POST.get("headers", "")
        body_str = request.POST.get("body", "")

        # Headers പാഴ്സ് ചെയ്യാൻ
        headers = {}
        if headers_str:
            try:
                headers = json.loads(headers_str)
            except:
                pass

        # POST Body പാഴ്സ് ചെയ്യാൻ
        data = None
        json_data = None
        if method == "POST" and body_str:
            try:
                json_data = json.loads(body_str)
            except:
                data = body_str

        try:
            # റിക്വസ്റ്റ് അയക്കുന്നു
            if method == "GET":
                response = requests.get(url, headers=headers, timeout=10)
            elif method == "POST":
                response = requests.post(url, headers=headers, json=json_data, data=data, timeout=10)
            
            # റെസ്പോൺസ് ഫോർമാറ്റ് ചെയ്യുന്നു
            try:
                formatted_response = json.dumps(response.json(), indent=4)
            except:
                formatted_response = response.text

            context = {
                "success": True,
                "status_code": response.status_code,
                "time_taken": f"{response.elapsed.total_seconds():.2f}s",
                "response": formatted_response,
            }
        except Exception as e:
            context = {
                "success": False,
                "error": str(e)
            }

        return render(request, "api_tester/_response.html", context)
    
    return render(request, "api_tester/_response.html", {"success": False, "error": "Invalid Request"})