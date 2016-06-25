DECLARE

    -- Standard Parameters.   
    p_api_version          NUMBER;
    p_init_msg_list        VARCHAR2(30);
    p_commit               VARCHAR2(30);

    -- Parameters for WSH_DELIVERY_DETAILS_PUB.Detail_to_Delivery   
    p_delivery_id          NUMBER;
    delivery_name          VARCHAR2(30);
    p_TabOfDelDet          WSH_DELIVERY_DETAILS_PUB.id_tab_type;
    p_action               VARCHAR2(30);

    -- out parameters   
    x_return_status        VARCHAR2(10);
    x_msg_count            NUMBER;
    x_msg_data             VARCHAR2(2000);
    x_msg_details          VARCHAR2(3000);
    x_msg_summary          VARCHAR2(3000);

    -- Handle exceptions   
    vApiErrorException     EXCEPTION;

BEGIN
    -- Initialize return status    
    x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;

    -- Call this procedure to initialize applications parameters    
    FND_GLOBAL.APPS_INITIALIZE(
								   user_id      => 1318
								,  resp_id      => 21623
								,  resp_appl_id => 660);

    -- Values for WSH_DELIVERY_DETAILS_PUB.Detail_to_Delivery    
    p_delivery_id         := 3773376;    -- Delivery ID
    p_TabOfDelDet(1)      := 3963471;    -- Delivery Detail ID
    p_action              := 'UNASSIGN'; -- Action (UNASSIGN)

    -- Call to WSH_DELIVERY_DETAILS_PUB.Detail_to_Delivery.
    WSH_DELIVERY_DETAILS_PUB.Detail_to_Delivery (
												  p_api_version      => 1.0,
												  p_init_msg_list    => p_init_msg_list,
												  p_commit           => p_commit,
												  x_return_status    => x_return_status,
												  x_msg_count        => x_msg_count,
												  x_msg_data         => x_msg_data,
												  p_TabOfDelDets     => p_TabOfDelDet,
												  p_action           => p_action,
												  p_delivery_id      => p_delivery_id,
												  p_delivery_name    => delivery_name
												);

    IF (x_return_status <> WSH_UTIL_CORE.G_RET_STS_SUCCESS) 
	THEN
        RAISE vApiErrorException;
    ELSE
        DBMS_OUTPUT.PUT_LINE('The unpacked container line '||p_TabOfDelDet(1)|| ' is unassigned successfully from delivery '|| p_delivery_id);
    END IF;
EXCEPTION
    WHEN vApiErrorException 
	THEN
        WSH_UTIL_CORE.get_messages('Y', x_msg_summary, x_msg_details,x_msg_count);
        IF x_msg_count > 1 
		THEN
            x_msg_data := x_msg_summary || x_msg_details;
            DBMS_OUTPUT.PUT_LINE('Message Data : '||x_msg_data);
        ELSE
            x_msg_data := x_msg_summary;
            DBMS_OUTPUT.PUT_LINE('Message Data : '||x_msg_data);
        END IF;  
    WHEN OTHERS
    THEN
		DBMS_OUTPUT.PUT_LINE('Unexpected Error: '||SQLERRM);
END;  
/

--Once the API is run then the delivery is unassigned from Delivery Detail.
--select * from wsh_delivery_assignments where delivery_detail_id = 3963471;