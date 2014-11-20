/*============================================================================== 
$Header: MRPFAPIB.pls 115.18 2002/12/05 01:04:09 ichoudhu ship $

              (c) Copyright Oracle Corporation 1992
                        All Rights Reserved

    OVERVIEW:
    This script creates a package that imports forecast entries

==============================================================================*/
REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb \
REM dbdrv: checkfile:~PROD:~PATH:~FILE
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR EXIT FAILURE ROLLBACK


CREATE OR REPLACE PACKAGE BODY MRP_FORECAST_INTERFACE_PK AS
    /* $Header: MRPFAPIB.pls 115.18 2002/12/05 01:04:09 ichoudhu ship $ */

mrdebug                 BOOLEAN             := FALSE;
REJECT_INVALID_DATE     CONSTANT INTEGER    := 1;
IMPORTED_ITEM_FORECAST  CONSTANT INTEGER    := 3;
SHIFT_INVALID_DATE_FWD  CONSTANT INTEGER    := 2;
SHIFT_INVALID_DATE_BWD  CONSTANT INTEGER    := 3;

G_PKG_NAME              CONSTANT VARCHAR2(30) := 'MRP_Forecast_Interface_PK';

FUNCTION    adjust_date(
                in_date             IN DATE,
                out_date            IN OUT NOCOPY DATE,
                bucket_type         NUMBER,
                workday_control     NUMBER,
                org_id              NUMBER) RETURN BOOLEAN IS
BEGIN
    IF workday_control = SHIFT_INVALID_DATE_FWD OR
       workday_control = REJECT_INVALID_DATE THEN
        out_date := mrp_calendar.next_work_day(org_id, bucket_type, in_date);
        /* Bug 1849709 */
        IF workday_control = REJECT_INVALID_DATE AND 
                  to_char(out_date,'MM/DD/RRRR') <> to_char(in_date,'MM/DD/RRRR')
        THEN
            RETURN FALSE;
        END IF;
    ELSIF workday_control = SHIFT_INVALID_DATE_BWD
    THEN
        out_date := mrp_calendar.prev_work_day(org_id, bucket_type, in_date);
    END IF;
    RETURN TRUE;
END adjust_date;

PROCEDURE set_interface_error(
                counter             IN      NUMBER ,
                forecast_interface  IN OUT NOCOPY  t_forecast_interface,
                error_message       IN      VARCHAR2 ) IS
BEGIN
    forecast_interface(counter).process_status := 4;
    forecast_interface(counter).error_message := error_message;
--    IF mrdebug = TRUE THEN
--        dbms_output.put_line('Error for row # '||to_char(counter));
--        dbms_output.put_line('Error message - '|| error_message);
--    END IF;
END;

FUNCTION create_for_entries(
                forecast_interface      IN OUT NOCOPY  t_forecast_interface)
        RETURN BOOLEAN IS
        var_low_index           NUMBER := 0;
        var_high_index          NUMBER := 0;
        counter                 NUMBER := 0;
        var_max_trx_id          NUMBER;
        dummy_var               VARCHAR2(2);
        var_for_date            DATE;
        var_for_end_date        DATE;
        var_request_id          NUMBER;
        var_user_id             NUMBER;
        error_message           VARCHAR2(240);
        delete_row              BOOLEAN := FALSE;
        p_result                varchar2(1);
        errcode                 VARCHAR2(240);
BEGIN
    SELECT  mrp_forecast_dates_s.nextval
    INTO    var_max_trx_id
    FROM    dual;

    var_low_index := forecast_interface.first;

    IF var_low_index IS NULL THEN
        RETURN TRUE;
    END IF;
    var_high_index := forecast_interface.last;
    counter := var_low_index;
    WHILE counter <= var_high_index
    LOOP
        delete_row := FALSE;
        error_message := NULL;
        IF forecast_interface(counter).process_status <> 2 THEN
            goto skip_row;
        END IF;
        --dbms_output.put_line('Action '||forecast_interface(counter).action);
  /* Begin change for Bug 1849709 */
   IF forecast_interface(counter).action IS NOT NULL AND
       forecast_interface(counter).action not in ('I','U','D') THEN
            fnd_message.set_name('MRP', 'GEN-INVALID ENTITY');
            fnd_message.set_token('ENTITY', 'E_FORECAST_ACTION', TRUE);
            fnd_message.set_token('VALUE',
                        forecast_interface(counter).action);
            error_message := fnd_message.get;
            set_interface_error(counter, forecast_interface, error_message);
    --        IF mrdebug = TRUE THEN
    --            dbms_output.put_line('Error for action - '||
    --                   forecast_interface(counter).action);
     --       END IF;
            goto skip_row;
     END IF;

     IF forecast_interface(counter).action IS NULL AND
             forecast_interface(counter).quantity >= 0 THEN
           IF forecast_interface(counter).transaction_id IS NOT NULL then
              IF forecast_interface(counter).quantity = 0 THEN
                  forecast_interface(counter).action := 'D';
              ELSE
                  forecast_interface(counter).action := 'U';
              END IF;
           ELSE
              forecast_interface(counter).action := 'I';
           END IF;
     END IF;
           
         
     IF forecast_interface(counter).action = 'D' AND
                forecast_interface(counter).transaction_id IS NOT NULL THEN
            delete_row := TRUE;
     END IF;

        /* Bug 1849709 */
        IF forecast_interface(counter).quantity < 0 
           -- OR
           -- forecast_interface(counter).quantity >  99999999.9 OR
           -- forecast_interface(counter).quantity = 0 
              AND delete_row = FALSE
        THEN
            fnd_message.set_name('MRP', 'GEN-INVALID ENTITY');
            fnd_message.set_token('ENTITY', 'E_FORECAST_QTY', TRUE);
            fnd_message.set_token('VALUE',
                to_char(forecast_interface(counter).quantity));
            error_message := fnd_message.get;
            set_interface_error(counter, forecast_interface, error_message);
--            IF mrdebug = TRUE THEN  
--                dbms_output.put_line('Error for Quantity - '||
--                    to_char(forecast_interface(counter).quantity));
--            END IF;
            goto skip_row;
        END IF;
                                    
     /* End of Change */
        IF forecast_interface(counter).confidence_percentage IS NULL
        THEN
            forecast_interface(counter).confidence_percentage := 0.0;
        END IF;

        IF forecast_interface(counter).confidence_percentage <= 0 OR
            forecast_interface(counter).confidence_percentage > 100
        THEN
            fnd_message.set_name('MRP', 'GEN-INVALID ENTITY');
            fnd_message.set_token('ENTITY', 'E_CONFIDENCE_PERCENT', TRUE);
            fnd_message.set_token('VALUE',
                to_char(forecast_interface(counter).confidence_percentage));
            error_message := fnd_message.get;
            set_interface_error(counter, forecast_interface, error_message);
--            IF mrdebug = TRUE THEN
--                dbms_output.put_line('Error for Confidence Pctg - '||
--                  to_char(forecast_interface(counter).confidence_percentage));
--            END IF;
            goto skip_row;
        END IF;

        IF forecast_interface(counter).workday_control is NULL
        THEN
            forecast_interface(counter).workday_control := REJECT_INVALID_DATE;
        END IF;

        IF forecast_interface(counter).workday_control <>
                SHIFT_INVALID_DATE_FWD AND
            forecast_interface(counter).workday_control <>
                SHIFT_INVALID_DATE_BWD AND
            forecast_interface(counter).workday_control <>
                REJECT_INVALID_DATE
        THEN
            fnd_message.set_name('MRP', 'GEN-INVALID ENTITY');
            fnd_message.set_token('ENTITY', 'E_WORKDAY_CONTROL', TRUE);
            fnd_message.set_token('VALUE',
                to_char(forecast_interface(counter).workday_control), FALSE);
            error_message := fnd_message.get;
            set_interface_error(counter, forecast_interface, error_message);
--            IF mrdebug = TRUE THEN
--                dbms_output.put_line('Error for Workday control - '||
--                    to_char(forecast_interface(counter).workday_control));
--            END IF;
            goto skip_row;
        END IF;

        BEGIN
       /* change for Bug 1849709 */
        IF forecast_interface(counter).action = 'U' OR
              forecast_interface(counter).action = 'D' THEN
          IF forecast_interface(counter).transaction_id IS NOT NULL THEN
            DELETE  FROM mrp_Forecast_dates
            WHERE   transaction_id = forecast_interface(counter).transaction_id
            and     organization_id =
                    forecast_interface(counter).organization_id
            and     forecast_designator =
                    forecast_interface(counter).forecast_designator;
            IF SQL%NOTFOUND THEN
                IF forecast_interface(counter).transaction_id > var_max_trx_id
                THEN
                    fnd_message.set_name('MRP', 'GEN-INVALID ENTITY');
                    fnd_message.set_token('ENTITY',
                        'E_TRANSACTION_ID', TRUE);
                    fnd_message.set_token('VALUE',
                    to_char(forecast_interface(counter).transaction_id));
                    error_message := fnd_message.get;
                    set_interface_error(counter,
                        forecast_interface, error_message);
     --               IF mrdebug = TRUE THEN
     --                  dbms_output.put_line('Error for Transaction Id - '||
     --                    to_char(forecast_interface(counter).transaction_id));
     --               END IF;
                    goto skip_row;
                ELSE
                    fnd_message.set_name('MRP', 'IMP-INVALID TRAN_ID');
                    error_message := fnd_message.get;
                    set_interface_error(counter,
                        forecast_interface, error_message);
      --              IF mrdebug = TRUE THEN
      --                  dbms_output.put_line('Error for Transaction Id - '||
      --                   to_char(forecast_interface(counter).transaction_id));
      --              END IF;
                    goto skip_row;
                END IF;
            END IF;
          END IF;
        END IF;
        END;

        BEGIN
            SELECT  'x'
            INTO    dummy_var
            FROM    mtl_parameters
            WHERE   organization_id =
                        forecast_interface(counter).organization_id
              AND process_enabled_flag = 'N';  /* 1485309 */

        EXCEPTION
            WHEN no_data_found THEN
                fnd_message.set_name('MRP', 'GEN-INVALID ENTITY');
                fnd_message.set_token('ENTITY', 'E_ORGANIZATION', TRUE);
                fnd_message.set_token('VALUE',
                    to_char(forecast_interface(counter).organization_id));
                error_message := fnd_message.get;
                set_interface_error(counter, forecast_interface, error_message);
--                IF mrdebug = TRUE THEN
--                    dbms_output.put_line('Error for Organization Id - '||
--                        to_char(forecast_interface(counter).organization_id));
--                END IF;
                goto skip_row;
        END;

        BEGIN
            SELECT  'x'
            INTO    dummy_var
            FROM    mtl_system_items
            WHERE   organization_id =
                        forecast_interface(counter).organization_id
            AND     inventory_item_id =
                        forecast_interface(counter).inventory_item_id;

        EXCEPTION
            WHEN no_data_found THEN
                fnd_message.set_name('MRP', 'GEN-INVALID ENTITY');
                fnd_message.set_token('ENTITY', 'E_INVENTORY_ITEM', TRUE);
                fnd_message.set_token('VALUE',
                    to_char(forecast_interface(counter).inventory_item_id));
                error_message := fnd_message.get;
                set_interface_error(counter, forecast_interface, error_message);
--                IF mrdebug = TRUE THEN
--                    dbms_output.put_line('Error for Item - '||
--                      to_char(forecast_interface(counter).inventory_item_id));
--                END IF;
                goto skip_row;
        END;

        BEGIN
            SELECT  'x'
            INTO    dummy_var
            FROM    mrp_forecast_designators
            WHERE   forecast_designator =
                        forecast_interface(counter).forecast_designator
            AND     NVL(disable_date, SYSDATE + 2) > TRUNC(SYSDATE)
            AND     forecast_set IS NOT NULL
            AND     organization_id =
                        forecast_interface(counter).organization_id;

            EXCEPTION
                WHEN no_data_found THEN
                    fnd_message.set_name('MRP', 'GEN-INVALID ENTITY');
                    fnd_message.set_token('ENTITY',
                        'E_FORECAST_NAME', TRUE);
                    fnd_message.set_token('VALUE',
                        forecast_interface(counter).forecast_designator);
                    error_message := fnd_message.get;
                    set_interface_error(counter, forecast_interface,
                        error_message);
--                    IF mrdebug = TRUE THEN
--                        dbms_output.put_line('Error for Forecast name - '||
--                            forecast_interface(counter).forecast_designator); 
--                    END IF;
                    goto skip_row;
        END;

        IF forecast_interface(counter).bucket_type IS null
        THEN
            forecast_interface(counter).bucket_type := 1;
        END IF;

        IF forecast_interface(counter).bucket_type <> 1 AND
                forecast_interface(counter).bucket_type <> 2 AND
                forecast_interface(counter).bucket_type <> 3
        THEN
            fnd_message.set_name('MRP', 'GEN-INVALID ENTITY');
            fnd_message.set_token('ENTITY', 'EC_BUCKET_TYPE', TRUE);
            fnd_message.set_token('VALUE',
                to_char(forecast_interface(counter).bucket_type));
            error_message := fnd_message.get;
            set_interface_error(counter, forecast_interface, error_message);
--            IF mrdebug = TRUE THEN
--                dbms_output.put_line('Error for Bucket type - '||
--                    to_char(forecast_interface(counter).bucket_type)); 
--            END IF;
            goto skip_row;
        END IF;

        IF forecast_interface(counter).forecast_date is null
        THEN
            fnd_message.set_name('MRP', 'GEN-INVALID ENTITY');
            fnd_message.set_token('ENTITY', 'EC_FORECAST_DATE', TRUE);
            fnd_message.set_token('VALUE', 'NULL');
            error_message := fnd_message.get;
            set_interface_error(counter, forecast_interface, error_message);
--            IF mrdebug = TRUE THEN
--                dbms_output.put_line('Error for Forecast date - NULL'); 
--            END IF;
            goto skip_row;
        END IF;

        IF adjust_date(forecast_interface(counter).forecast_date,
                        var_for_date,
                        forecast_interface(counter).bucket_type,
                        forecast_interface(counter).workday_control,
                        forecast_interface(counter).organization_id) = FALSE
        THEN
            fnd_message.set_name('MRP', 'GEN-INVALID ENTITY');
            fnd_message.set_token('ENTITY', 'EC_FORECAST_DATE', TRUE);
            fnd_message.set_token('VALUE',
                to_char(forecast_interface(counter).forecast_date));
            error_message := fnd_message.get;
            set_interface_error(counter, forecast_interface, error_message);
--            IF mrdebug = TRUE THEN
--                dbms_output.put_line('Error for Forecast date - '||
--                    to_char(forecast_interface(counter).forecast_date)); 
--            END IF;
            goto skip_row;
        END IF;

        IF forecast_interface(counter).forecast_end_date IS NOT NULL THEN
            IF adjust_date(forecast_interface(counter).forecast_end_date,
                    var_for_end_date,
                    forecast_interface(counter).bucket_type,
                    forecast_interface(counter).workday_control,
                    forecast_interface(counter).organization_id) = FALSE
            THEN
                fnd_message.set_name('MRP', 'IMP-invalid rate_end_date');
                error_message := fnd_message.get;
                set_interface_error(counter, forecast_interface, error_message);
--                IF mrdebug = TRUE THEN
--                    dbms_output.put_line('Error for Forecast end date - '||
--                      to_char(forecast_interface(counter).forecast_end_date));
--                END IF;
                goto skip_row;
            END IF;
            IF var_for_end_date < var_for_date THEN
                fnd_message.set_name('MRP', 'IMP-invalid rate_end_date');
                error_message := fnd_message.get;
                set_interface_error(counter, forecast_interface, error_message);
--                IF mrdebug = TRUE THEN
--                    dbms_output.put_line('Error for Forecast end date - '||
--                      to_char(forecast_interface(counter).forecast_end_date));
--                END IF;
                goto skip_row;
            END IF;
        END IF;

        IF (forecast_interface(counter).line_id IS NOT NULL) THEN
            BEGIN
              SELECT  'x'
              INTO    dummy_var
              FROM    wip_lines
              WHERE   organization_id = 
                                forecast_interface(counter).organization_id
              AND     line_id = forecast_interface(counter).line_id;

            EXCEPTION
              WHEN no_data_found THEN
                fnd_message.set_name('MRP', 'GEN-INVALID ENTITY');
                fnd_message.set_token('ENTITY', 'E_LINE', TRUE);
                fnd_message.set_token('VALUE',
                    to_char(forecast_interface(counter).line_id));
                error_message := fnd_message.get;
                set_interface_error(counter, forecast_interface, error_message);
--                IF mrdebug = TRUE THEN
--                    dbms_output.put_line('Error for Line - '||
--                        to_char(forecast_interface(counter).line_id)); 
--                END IF;
                goto skip_row;
            END;
        END IF; /* if f_i().line_id is not null */

    p_result := 'S';
    IF forecast_interface(counter).project_id IS NOT NULL THEN
                      p_result := PJM_PROJECT.VALIDATE_PROJ_REFERENCES
                         (  X_inventory_org_id => forecast_interface(counter).organization_id
                          , X_project_id      => forecast_interface(counter).project_id
                          , X_task_id         => forecast_interface(counter).task_id
                          , X_date1           => var_for_date
                          , X_date2           => var_for_end_date
                          , X_calling_function =>  'MRPFAPIB'
                          , X_error_code      => errcode
                         );
    END IF;
       
    IF (p_result = 'E') THEN
       error_message := SUBSTRB(fnd_message.get,1,240);
       set_interface_error(counter, forecast_interface, error_message);
       goto skip_row;
    END IF;


        /* Change for Bug 1849709 */
        IF (forecast_interface(counter).action in ('I','U') AND
             delete_row = FALSE )
        THEN    
--            dbms_output.put_line('Inserting row '||
--            forecast_interface(counter).forecast_designator);

/* 1336039 - SVAIDYAN: Insert attribute_category also. */

            INSERT INTO mrp_forecast_dates
            (
                transaction_id,
                last_update_date,
                last_updated_by,
                creation_date,
                created_by,
                last_update_login,
                inventory_item_id,
                organization_id,
                forecast_designator,
                forecast_date,
                rate_end_date,
                bucket_type,
                original_forecast_quantity,
                current_forecast_quantity,
                comments,
                confidence_percentage,
                source_organization_id,
                source_forecast_designator,
                origination_type,
                request_id,
                source_code,
                source_line_id,
                attribute1,
                attribute2,
                attribute3,
                attribute4,
                attribute5,
                attribute6,
                attribute7,
                attribute8,
                attribute9,
                attribute10,
                attribute11,
                attribute12,
                attribute13,
                attribute14,
                attribute15,
                old_transaction_id,
                to_update,
                project_id,
                task_id,
                line_id,
                attribute_category)
            VALUES
            (
                NVL(forecast_interface(counter).transaction_id,
                        mrp_forecast_dates_s.nextval),
                SYSDATE,
                NVL(forecast_interface(counter).last_updated_by, -1),
                SYSDATE,
                NVL(forecast_interface(counter).created_by, -1),
                NVL(forecast_interface(counter).last_update_login, -1),
                forecast_interface(counter).inventory_item_id,
                forecast_interface(counter).organization_id,
                forecast_interface(counter).forecast_designator,
                var_for_date,
                var_for_end_date,
                forecast_interface(counter).bucket_type,
                ROUND(forecast_interface(counter).quantity, 6),
                ROUND(forecast_interface(counter).quantity, 6),
                forecast_interface(counter).comments,
                forecast_interface(counter).confidence_percentage,
                NULL,
                NULL,
                IMPORTED_ITEM_FORECAST,
                forecast_interface(counter).request_id,
                forecast_interface(counter).source_code,
                forecast_interface(counter).source_line_id,
                forecast_interface(counter).attribute1,
                forecast_interface(counter).attribute2,
                forecast_interface(counter).attribute3,
                forecast_interface(counter).attribute4,
                forecast_interface(counter).attribute5,
                forecast_interface(counter).attribute6,
                forecast_interface(counter).attribute7,
                forecast_interface(counter).attribute8,
                forecast_interface(counter).attribute9,
                forecast_interface(counter).attribute10,
                forecast_interface(counter).attribute11,
                forecast_interface(counter).attribute12,
                forecast_interface(counter).attribute13,
                forecast_interface(counter).attribute14,
                forecast_interface(counter).attribute15,
                NULL,
                NULL,
                forecast_interface(counter).project_id, 
                forecast_interface(counter).task_id, 
                forecast_interface(counter).line_id,
                forecast_interface(counter).attribute_category
        );

--        dbms_output.put_line(to_Char(SQL%ROWCOUNT));
       -- COMMIT;
        END IF;

        forecast_interface(counter).process_status := 5;

        <<skip_row>>
            counter := forecast_interface.next(counter);
    END LOOP;

    mrp_manager_pk.create_forecast_items(-1, -1, NULL);
    RETURN TRUE;
END create_for_entries;


FUNCTION del_for_entries(
                tab_forecast_designator     IN OUT NOCOPY  t_forecast_designator)
        RETURN BOOLEAN IS
        var_low_index   NUMBER := 0;
        var_high_index  NUMBER := 0;
        counter         NUMBER := 0;
BEGIN
    var_low_index := tab_forecast_designator.first;
    IF var_low_index IS NULL
    THEN
        RETURN TRUE;
    END IF;
    var_high_index := tab_forecast_designator.last;

    counter := var_low_index;
    WHILE counter <= var_high_index
    LOOP
        BEGIN

	    IF tab_forecast_designator(counter).inventory_item_id IS NULL THEN
            	delete  from mrp_forecast_dates
            	where   forecast_designator = 
                	tab_forecast_designator(counter).forecast_designator
            	and     organization_id = 
                	tab_forecast_designator(counter).organization_id;

	    ELSE
		delete  from mrp_forecast_dates
                where   forecast_designator =
                        tab_forecast_designator(counter).forecast_designator
                and     organization_id =
                        tab_forecast_designator(counter).organization_id
            	and 	inventory_item_id = 
			tab_forecast_designator(counter).inventory_item_id;
	    END IF;

--            IF SQL%NOTFOUND THEN
--                IF mrdebug = TRUE THEN
--                    dbms_output.put_line('Forecast designator/Org '||
--                   tab_forecast_designator(counter).forecast_designator||'/'||
--                  to_char(tab_forecast_designator(counter).organization_id) ||
--                    ' has no rows in mrp_forecast_dates');
--                END IF;
--            END IF;
        END;

        BEGIN

	    IF tab_forecast_designator(counter).inventory_item_id IS NULL THEN 
            	delete  from mrp_forecast_items
            	where   forecast_designator = 
                	tab_forecast_designator(counter).forecast_designator
            	and     organization_id = 
                	tab_forecast_designator(counter).organization_id;
	    ELSE
		delete  from mrp_forecast_items
                where   forecast_designator =
                        tab_forecast_designator(counter).forecast_designator
                and     organization_id =
                        tab_forecast_designator(counter).organization_id
	    	and     inventory_item_id =
			tab_forecast_designator(counter).inventory_item_id;
	    END IF;

--            IF SQL%NOTFOUND  THEN
--                IF mrdebug = TRUE THEN
--                    dbms_output.put_line('Forecast designator/Org '||
--                   tab_forecast_designator(counter).forecast_designator||'/'||
--                  to_char(tab_forecast_designator(counter).organization_id) ||
--                    ' has no rows in mrp_forecast_items');
--                END IF;
--            END IF;
        END;

        counter := tab_forecast_designator.next(counter);
    END LOOP;
    RETURN TRUE;
END del_for_entries;

FUNCTION mrp_forecast_interface(
                forecast_interface      IN OUT NOCOPY  t_forecast_interface)
        RETURN BOOLEAN IS
        var_bool    BOOLEAN;
BEGIN
    mrdebug := FND_PROFILE.VALUE('MRP_DEBUG') = 'Y';
    var_bool := create_for_entries(forecast_interface);
    RETURN var_bool;
--    COMMIT;
END mrp_forecast_interface;

FUNCTION mrp_forecast_interface(
                forecast_designator     IN OUT NOCOPY  t_forecast_designator)
        RETURN BOOLEAN IS
        var_bool    BOOLEAN;
BEGIN
    mrdebug := FND_PROFILE.VALUE('MRP_DEBUG') = 'Y';
    var_bool := del_for_entries(forecast_designator);
    RETURN var_bool;
--    COMMIT;
END mrp_forecast_interface;

FUNCTION mrp_forecast_interface(
                forecast_interface      IN OUT NOCOPY  t_forecast_interface,
                forecast_designator     IN OUT NOCOPY  t_forecast_designator)
        RETURN BOOLEAN IS
        var_bool    BOOLEAN;
BEGIN

    mrdebug := FND_PROFILE.VALUE('MRP_DEBUG') = 'Y';

    var_bool := del_for_entries(forecast_designator);
    IF var_bool = FALSE THEN
        RETURN FALSE;
    END IF;
    var_bool := create_for_entries(forecast_interface);

    IF var_bool = FALSE THEN
        RETURN FALSE;
    END IF;
--    COMMIT;
    RETURN TRUE;
END mrp_forecast_interface;

PROCEDURE quantity_per_day(x_return_status OUT NOCOPY VARCHAR2,
	x_msg_count OUT NOCOPY NUMBER,
	x_msg_data OUT NOCOPY VARCHAR2,
	p_organization_id IN NUMBER,
	p_workday_control IN NUMBER,
	p_start_date IN DATE,
	p_end_date IN DATE,
	p_quantity IN NUMBER,
	x_workday_count OUT NOCOPY NUMBER,
	x_quantity_per_day OUT NOCOPY QUANTITY_PER_DAY_TBL_TYPE) IS

  CURSOR C1(p_count NUMBER, p_start_date DATE, p_end_date DATE) IS
  SELECT calendar_date, 
	p_quantity/p_count
  FROM mtl_parameters param,
	bom_calendar_dates cal
  WHERE param.organization_id = p_organization_id
    AND param.calendar_exception_set_id = cal.exception_set_id
    AND param.calendar_code = cal.calendar_code
    AND cal.seq_num IS NOT NULL
    AND cal.calendar_date BETWEEN p_start_date AND p_end_date
    AND cal.calendar_date <> p_end_date;

  l_new_start_date	DATE;
  l_new_end_date	DATE;
  l_count		NUMBER;
  l_quantity_per_day    QUANTITY_PER_DAY_TBL_TYPE;
  l_work_date		DATE;
  l_quantity		NUMBER;
  i			NUMBER := 1;

BEGIN

  IF adjust_date(p_start_date, l_new_start_date, 1, p_workday_control,
                 p_organization_id) = FALSE
  THEN
    fnd_message.set_name('MRP', 'GEN-INVALID ENTITY');
    fnd_message.set_token('ENTITY', 'EC_FORECAST_DATE', TRUE);
    fnd_message.set_token('VALUE', to_char(p_start_date));
    fnd_msg_pub.add;
    RAISE FND_API.G_EXC_ERROR;
  END IF;
  IF adjust_date(p_end_date, l_new_end_date, 1, p_workday_control,
                 p_organization_id) = FALSE
  THEN
    fnd_message.set_name('MRP', 'GEN-INVALID ENTITY');
    fnd_message.set_token('ENTITY', 'EC_FORECAST_DATE', TRUE);
    fnd_message.set_token('VALUE', to_char(p_end_date));
    fnd_msg_pub.add;
    RAISE FND_API.G_EXC_ERROR;
  END IF;

  l_count := mrp_calendar.days_between(p_organization_id,1,
	l_new_start_date,l_new_end_date);

  x_workday_count := l_count;

  OPEN C1(l_count, l_new_start_date, l_new_end_date);
  LOOP 
    EXIT WHEN C1%NOTFOUND;
    FETCH C1 INTO
        l_work_date,
	l_quantity;

    l_quantity_per_day(i).work_date := l_work_date;
    l_quantity_per_day(i).quantity := l_quantity;
 
    i := i + 1;
  END LOOP;
  CLOSE C1;

  x_quantity_per_day := l_quantity_per_day;

  x_return_status := FND_API.G_RET_STS_SUCCESS;

EXCEPTION

  WHEN FND_API.G_EXC_ERROR THEN

        x_return_status := FND_API.G_RET_STS_ERROR;

        --  Get message count and data

        FND_MSG_PUB.Count_And_Get
        (   p_count                       => x_msg_count
        ,   p_data                        => x_msg_data
        );

  WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN

        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

        --  Get message count and data

        FND_MSG_PUB.Count_And_Get
        (   p_count                       => x_msg_count
        ,   p_data                        => x_msg_data
        );

  WHEN OTHERS THEN

        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

        IF FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
        THEN
            FND_MSG_PUB.Add_Exc_Msg
            (   G_PKG_NAME
            ,   'Quantity_Per_Day'
            );
        END IF;

        --  Get message count and data

        FND_MSG_PUB.Count_And_Get
        (   p_count                       => x_msg_count
        ,   p_data                        => x_msg_data
        );

END quantity_per_day;
END; -- package
/
commit
/
exit
/
