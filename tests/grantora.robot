*** Settings ***
Library    SSHLibrary
Library    Browser

*** Variables ***
${ADMIN_USER}    admin
${ADMIN_PASSWORD}    Nethesis,1234
${module_id}    ${EMPTY}
${workspace_id}    ${EMPTY}
${application_id}    ${EMPTY}
${user_id}    ${EMPTY}
${role_id}    ${EMPTY}
${capability_id}    ${EMPTY}
${agent_id}    ${EMPTY}
${agent_token}    ${EMPTY}

*** Keywords ***
Login to cluster-admin
    New Page    https://${NODE_ADDR}/cluster-admin/
    Fill Text    text="Username"    ${ADMIN_USER}
    Click    button >> text="Continue"
    Fill Text    text="Password"    ${ADMIN_PASSWORD}
    Click    button >> text="Log in"
    Wait For Elements State    css=#main-content    visible    timeout=10s

Run module action
    [Arguments]    ${action}    ${data}={}
    ${output}  ${rc} =    Execute Command    api-cli run module/${module_id}/${action} --data '${data}'
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    RETURN    ${output}

Run module action without input
    [Arguments]    ${action}
    ${output}  ${rc} =    Execute Command    api-cli run module/${module_id}/${action}
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    RETURN    ${output}

Parse JSON
    [Arguments]    ${output}
    ${payload} =    Evaluate    json.loads(r'''${output}''')    modules=json
    RETURN    ${payload}

Get module status
    ${output} =    Run module action without input    get-status
    ${status} =    Parse JSON    ${output}
    RETURN    ${status}

*** Test Cases ***
Check if grantora is installed correctly
    ${output}  ${rc} =    Execute Command    add-module ${IMAGE_URL} 1
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    &{output} =    Evaluate    json.loads(r'''${output}''')    modules=json
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
    ${configuration_output} =    Run module action without input    get-configuration
    ${configuration} =    Parse JSON    ${configuration_output}
    ${user_domain} =    Evaluate    next((domain["name"] for domain in $configuration["available_user_domains"] if domain.get("reachable")), "")
    ${configure_data} =    Evaluate    json.dumps({"host":"grantora.dom.test","lets_encrypt":False,"sync_users_enabled": bool($user_domain), **({"user_domain": $user_domain} if $user_domain else {})})    modules=json
    Run module action    configure-module    ${configure_data}

Check grantora status and pod topology
    ${status} =    Get module status
    Should Be True    ${status["configured"]}
    Should Be Equal    ${status["public_base_url"]}    https://grantora.dom.test
    Should Be Equal    ${status["pod"]["name"]}    grantora
    Should Contain    ${status["containers"]}    postgres
    Should Contain    ${status["containers"]}    apisix_etcd
    Should Contain    ${status["containers"]}    api
    Should Contain    ${status["containers"]}    apisix
    Should Contain    ${status["container_versions"]}    api
    Should Contain    ${status["units"]}    grantora.service
    Should Contain    ${status["units"]}    grantora-postgres.service
    Should Contain    ${status["units"]}    grantora-apisix-etcd.service
    Should Contain    ${status["units"]}    grantora-api.service
    Should Contain    ${status["units"]}    grantora-apisix.service
    Should Be True    ${status["healthz"].get("ok", False)}
    Should Contain    ${status["readyz"]}    ok
    Should Contain    ${status["apisix_sync"]}    ok
    Should Be True    ${status["metrics"]["private"]}

Check grantora public runtime route
    ${openapi_status}  ${openapi_rc} =    Execute Command    curl --resolve grantora.dom.test:443:127.0.0.1 --insecure --silent --output /dev/null --write-out '%{http_code}' --max-time 10 https://grantora.dom.test/v1/openapi.json
    ...    return_rc=True
    Should Be Equal As Integers    ${openapi_rc}  0
    Should Match Regexp    ${openapi_status}    ^(200|401|403)$

Check grantora security boundaries
    ${output} =    Run module action without input    run-smoke
    ${smoke} =    Parse JSON    ${output}
    Should Be True    ${smoke["checks"]["security"]["ok"]}
    Should Be True    ${smoke["checks"]["security"]["checks"]["runtime_private_paths"]["ok"]}
    Should Be True    ${smoke["checks"]["security"]["checks"]["pod_port_exposure"]["ok"]}
    Should Be True    ${smoke["checks"]["security"]["checks"]["secret_file_modes"]["ok"]}
    Should Be True    ${smoke["checks"]["runtime_discovery"]["ok"]}
    ${admin_status}  ${admin_rc} =    Execute Command    curl --resolve grantora.dom.test:443:127.0.0.1 --insecure --silent --output /dev/null --write-out '%{http_code}' --max-time 10 https://grantora.dom.test/v1/admin/apisix/status
    ...    return_rc=True
    Should Be Equal As Integers    ${admin_rc}  0
    Should Not Match Regexp    ${admin_status}    ^2[0-9][0-9]$
    ${metrics_status}  ${metrics_rc} =    Execute Command    curl --resolve grantora.dom.test:443:127.0.0.1 --insecure --silent --output /dev/null --write-out '%{http_code}' --max-time 10 https://grantora.dom.test/metrics
    ...    return_rc=True
    Should Be Equal As Integers    ${metrics_rc}  0
    Should Not Match Regexp    ${metrics_status}    ^2[0-9][0-9]$

Check grantora pod exposes only the runtime port
    ${output} =    Run module action without input    run-smoke
    ${smoke} =    Parse JSON    ${output}
    Should Be True    ${smoke["checks"]["security"]["checks"]["pod_port_exposure"]["ok"]}
    Should Be Empty    ${smoke["checks"]["security"]["checks"]["pod_port_exposure"]["unexpected"]}

Check grantora user sync action
    ${status} =    Get module status
    IF    ${status["sync_users_enabled"]}
        ${output} =    Run module action without input    sync-users
        ${sync} =    Parse JSON    ${output}
        Should Be Equal    ${sync["domain"]}    ${status["selected_user_domain"]}
        Should Be Equal As Integers    ${sync["errors"]}    0
    ELSE
        Log    User sync is disabled because no reachable account domain was available.
    END

Create demo capability flow
    ${bootstrap_output} =    Run module action    bootstrap-workspace    {}
    ${bootstrap} =    Parse JSON    ${bootstrap_output}
    Set Global Variable    ${workspace_id}    ${bootstrap["workspace"]["id"]}
    Set Global Variable    ${role_id}    ${bootstrap["roles"]["read_only"]["id"]}
    ${application_output} =    Run module action    create-application    {"workspace_id":"${workspace_id}","slug":"mock-phonebook","provider_type":"mock","base_url":"https://mock.example.test"}
    ${application} =    Parse JSON    ${application_output}
    Set Global Variable    ${application_id}    ${application["application"]["id"]}
    ${user_output} =    Run module action    create-user    {"workspace_id":"${workspace_id}","external_id":"robot-user","display_name":"Robot User"}
    ${user} =    Parse JSON    ${user_output}
    Set Global Variable    ${user_id}    ${user["user"]["id"]}
    ${capability_output} =    Run module action    create-capability-from-template    {"workspace_id":"${workspace_id}","template_id":"mock.phonebook.search","application_instance_id":"${application_id}","id":"robot.mock.phonebook.search","name":"Robot mock phonebook search"}
    ${capability} =    Parse JSON    ${capability_output}
    Set Global Variable    ${capability_id}    ${capability["capability"]["id"]}
    ${agent_output} =    Run module action    create-agent    {"workspace_id":"${workspace_id}","slug":"robot-agent","display_name":"Robot Agent","store_token":true}
    ${agent} =    Parse JSON    ${agent_output}
    Set Global Variable    ${agent_id}    ${agent["agent"]["id"]}
    Set Global Variable    ${agent_token}    ${agent["agent_token"]}
    ${binding_output} =    Run module action    create-binding    {"workspace_id":"${workspace_id}","agent_id":"${agent_id}","user_id":"${user_id}","capability_id":"${capability_id}","role_id":"${role_id}"}
    ${binding} =    Parse JSON    ${binding_output}
    Should Contain    ${binding}    binding
    ${smoke_output} =    Run module action without input    run-smoke
    ${smoke} =    Parse JSON    ${smoke_output}
    Should Be True    ${smoke["ok"]}

Invoke demo capability through APISIX
    Should Not Be Empty    ${agent_token}
    ${invoke_status}  ${invoke_rc} =    Execute Command    curl --resolve grantora.dom.test:443:127.0.0.1 --insecure --silent --output /dev/null --write-out '%{http_code}' --max-time 10 -X POST https://grantora.dom.test/v1/invoke/${capability_id} -H 'Authorization: Bearer ${agent_token}' -H 'Content-Type: application/json' -d '{"user":"robot-user","input":{"query":"Mario","limit":1}}'
    ...    return_rc=True
    Should Be Equal As Integers    ${invoke_rc}  0
    Should Match Regexp    ${invoke_status}    ^2[0-9][0-9]$

Check backup and restore smoke
    ${backup_output} =    Run module action without input    backup-module
    ${backup} =    Parse JSON    ${backup_output}
    Should Be True    ${backup["size_bytes"]} > 0
    ${restore_output} =    Run module action without input    restore-module
    ${restore} =    Parse JSON    ${restore_output}
    Should Be True    ${restore["ok"]}
    Should Be True    ${restore["smoke"]["ok"]}
    ${invoke_status}  ${invoke_rc} =    Execute Command    curl --resolve grantora.dom.test:443:127.0.0.1 --insecure --silent --output /dev/null --write-out '%{http_code}' --max-time 10 -X POST https://grantora.dom.test/v1/invoke/${capability_id} -H 'Authorization: Bearer ${agent_token}' -H 'Content-Type: application/json' -d '{"user":"robot-user","input":{"query":"Mario","limit":1}}'
    ...    return_rc=True
    Should Be Equal As Integers    ${invoke_rc}  0
    Should Match Regexp    ${invoke_status}    ^2[0-9][0-9]$

Check same-version upgrade smoke
    ${status} =    Get module status
    ${upgrade_data} =    Evaluate    json.dumps({"grantora_version": $status["grantora_version"], "grantora_image": $status["grantora_image"], "pull": False})    modules=json
    ${upgrade_output} =    Run module action    upgrade-module    ${upgrade_data}
    ${upgrade} =    Parse JSON    ${upgrade_output}
    Should Be True    ${upgrade["ok"]}
    Should Be Equal    ${upgrade["upgrade"]["status"]}    ok

Check disabled agent and missing binding denials
    ${unbound_agent_output} =    Run module action    create-agent    {"workspace_id":"${workspace_id}","slug":"robot-unbound-agent","display_name":"Robot Unbound Agent","store_token":false}
    ${unbound_agent} =    Parse JSON    ${unbound_agent_output}
    ${unbound_token} =    Set Variable    ${unbound_agent["agent_token"]}
    Should Not Be Empty    ${unbound_token}
    ${unbound_status}  ${unbound_rc} =    Execute Command    curl --resolve grantora.dom.test:443:127.0.0.1 --insecure --silent --output /dev/null --write-out '%{http_code}' --max-time 10 -X POST https://grantora.dom.test/v1/invoke/${capability_id} -H 'Authorization: Bearer ${unbound_token}' -H 'Content-Type: application/json' -d '{"user":"robot-user","input":{"query":"Mario","limit":1}}'
    ...    return_rc=True
    Should Be Equal As Integers    ${unbound_rc}  0
    Should Match Regexp    ${unbound_status}    ^(401|403)$
    ${other_user_status}  ${other_user_rc} =    Execute Command    curl --resolve grantora.dom.test:443:127.0.0.1 --insecure --silent --output /dev/null --write-out '%{http_code}' --max-time 10 -X POST https://grantora.dom.test/v1/invoke/${capability_id} -H 'Authorization: Bearer ${agent_token}' -H 'Content-Type: application/json' -d '{"user":"other-user","input":{"query":"Mario","limit":1}}'
    ...    return_rc=True
    Should Be Equal As Integers    ${other_user_rc}  0
    Should Match Regexp    ${other_user_status}    ^(401|403)$
    ${disable_output} =    Run module action    disable-agent    {"agent_id":"${agent_id}"}
    ${disable} =    Parse JSON    ${disable_output}
    Should Contain    ${disable}    agent
    ${disabled_status}  ${disabled_rc} =    Execute Command    curl --resolve grantora.dom.test:443:127.0.0.1 --insecure --silent --output /dev/null --write-out '%{http_code}' --max-time 10 -X POST https://grantora.dom.test/v1/invoke/${capability_id} -H 'Authorization: Bearer ${agent_token}' -H 'Content-Type: application/json' -d '{"user":"robot-user","input":{"query":"Mario","limit":1}}'
    ...    return_rc=True
    Should Be Equal As Integers    ${disabled_rc}  0
    Should Match Regexp    ${disabled_status}    ^(401|403)$

Check if grantora is removed correctly
    ${rc} =    Execute Command    remove-module --no-preserve ${module_id}
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0
