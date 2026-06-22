import os
def ok():
    os.system("echo backdoor")  # malicious, never CI-checked
    return 3
