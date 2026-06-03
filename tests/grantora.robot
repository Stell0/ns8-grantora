*** Settings ***
Library    SSHLibrary
Library    Browser

*** Variables ***
${ADMIN_USER}    admin
${ADMIN_PASSWORD}    Nethesis,1234
${module_id}    ${EMPTY}

*** Keywords ***
Login to cluster-admin
    New Page    https://${NODE_ADDR}/cluster-admin/
    Fill Text    text="Username"    ${ADMIN_USER}
    Click    button >> text="Continue"
    Fill Text    text="Password"    ${ADMIN_PASSWORD}
    Click    button >> text="Log in"
    Wait For Elements State    css=#main-content    visible    timeout=10s

*** Test Cases ***
Check if grantora is installed correctly
    ${output}  ${rc} =    Execute Command    add-module ${IMAGE_URL} 1
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    &{output} =    Evaluate    ${output}
    Set Global Variable    ${module_id}    ${output.module_id}

Take screenshots
    [Tags]    ui
    New Browser    chromium    headless=True
    New Context    ignoreHTTPSErrors=True
    Login to cluster-admin
    Go To    https://${NODE_ADDR}/cluster-admin/#/apps/${module_id}
    Wait For Elements State    iframe >>> h2 >> text="Status"    visible    timeout=10s
    Sleep    5s
    Take Screenshot    filename=${OUTPUT DIR}/browser/screenshot/1._Status.png
    Go To    https://${NODE_ADDR}/cluster-admin/#/apps/${module_id}?page=settings
    Wait For Elements State    iframe >>> h2 >> text="Settings"    visible    timeout=10s
    Sleep    5s
    Take Screenshot    filename=${OUTPUT DIR}/browser/screenshot/2._Settings.png
    Close Browser

Check if grantora can be configured
    ${rc} =    Execute Command    api-cli run module/${module_id}/configure-module --data '{"host":"grantora.dom.test","lets_encrypt":false}'
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

Check grantora security boundaries
    ${output}  ${rc} =    Execute Command    api-cli run module/${module_id}/run-smoke
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    ${smoke} =    Evaluate    json.loads(r'''${output}''')    modules=json
    Should Be True    ${smoke["checks"]["security"]["ok"]}
    Should Be True    ${smoke["checks"]["security"]["checks"]["runtime_private_paths"]["ok"]}
    Should Be True    ${smoke["checks"]["security"]["checks"]["pod_port_exposure"]["ok"]}
    Should Be True    ${smoke["checks"]["security"]["checks"]["secret_file_modes"]["ok"]}
    ${admin_status}  ${admin_rc} =    Execute Command    curl --resolve grantora.dom.test:443:127.0.0.1 --insecure --silent --output /dev/null --write-out '%{http_code}' --max-time 10 https://grantora.dom.test/v1/admin/apisix/status
    ...    return_rc=True
    Should Be Equal As Integers    ${admin_rc}  0
    Should Not Match Regexp    ${admin_status}    ^2[0-9][0-9]$
    ${metrics_status}  ${metrics_rc} =    Execute Command    curl --resolve grantora.dom.test:443:127.0.0.1 --insecure --silent --output /dev/null --write-out '%{http_code}' --max-time 10 https://grantora.dom.test/metrics
    ...    return_rc=True
    Should Be Equal As Integers    ${metrics_rc}  0
    Should Not Match Regexp    ${metrics_status}    ^2[0-9][0-9]$

Check if grantora is removed correctly
    ${rc} =    Execute Command    remove-module --no-preserve ${module_id}
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0
