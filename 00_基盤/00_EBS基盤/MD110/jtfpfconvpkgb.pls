REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb \
REM dbdrv: checkfile:~PROD:~PATH:~FILE


SET VERIFY OFF;
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY JTF_PF_CONV_PKG AS
/* $Header: jtfpfconvpkgb.pls 115.27 2006/09/11 09:40:46 pchallag noship $ */
/*===========================================================================+
 |               Copyright (c) 2002 Oracle Corporation                       |
 |                  Redwood Shores, California, USA                          |
 |                       ALL rights reserved.                                |
 +===========================================================================+
 |   FILE NAME                                                               |
 |             jtfpfconvpkgb.pls			                     |
 |                                                                           |
 |   Description                                                             |
 |                                                                           |
 |     This FILE contains THE PACKAGE BODY FOR THE                           |
 |     JTF_PF_CONV_PKG , which IS THE PLSQL INTERFACE FOR THE                |
 |     jsp (activity) LOGGING project                                        |
 |                                                                           |
 |     Modification History:                                                 |
 |    05-Feb-2004     Modified  navkumar                                     |
 |                       fixed midnight-straddle bug going in %_SUMM tables  |
 |                       split migrate_data to _stats and _raw for           |
 |                       troubleshooting                                     |
 |    08-Jan-2004     Modified  angunda                                      |
 |                       modified migrate_data to write to JTF_PF_%_SUMM     |
 |                       Added TECH_STACK logic				     |
 |    14-Apr-2002     Modified  navkumar                                     |
 |                       added a suite OF PL/SQL FUNCTIONS and procedures    |
 |    11-Apr-2002     Created   bsanghav                                     |
 |    17-Feb-2010     Modified  SCS T.Kitagawa                               |
 |                              BUG:9365233 increased variable to 4000 and   |
 |                              protected against an overrun                 |
 |___________________________________________________________________________|*/

	last_migrate_day DATE;
   /*============================================================================================================	
    |  Writes THE Page flow data coming IN FROM THE JAVA layer INTO Advanced Queue
    |  INTO JTF_PF_PARAMS_TABLE 
    |  This IS an autonomous TRANSACTION i.e. It does NOT matter whether THE parent TRANSACTION
    |  commited OR rolled back , this TRANSACTION will COMMIT IF ALL goes well
   ============================================================================================================*/
   PROCEDURE writePFObject(obj JTF_PF_PAGE_OBJECT,write_to_jtf INTEGER,tech_stack VARCHAR2,dbdate OUT DATE) IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	pObject JTF_PF_PAGE_OBJECT;
        enqueue_options     dbms_aq.enqueue_options_t;
        message_properties  dbms_aq.message_properties_t;
        message_handle      RAW(16);
	dummyPageObj        JTF_PF_PAGE_OBJECT;
	seq_num             INTEGER;  
   BEGIN     
       SELECT JTF_PF_SEQ.NEXTVAL INTO seq_num FROM dual;
       SELECT sysdate INTO dbdate FROM dual;   
       dummyPageObj := JTF_PF_PAGE_OBJECT(JTF_PF_INFO_OBJECT(seq_num,obj.info.Day,obj.info.Timestamp),obj.dpf,obj.ses,obj.jsp,
					  obj.loc,obj.lang,obj.client,obj.params,
                                          obj.cookies,obj.headers);
       IF (write_to_jtf = 1) THEN 
           INSERT INTO jtf_pf_repository( 
			pageobject, object_version_number,
			created_by, creation_date,
			last_updated_by, last_update_date, tech_stack)
		VALUES (dummyPageObj, 0, 690, obj.info.Day, 690, obj.info.Timestamp, tech_stack);
       ELSE 
           message_properties.correlation := seq_num;
           message_properties.expiration := 24*60*60; -- messages expire in one day after first dequeue
           dbms_aq.enqueue(queue_name => qname,           
       	 	           enqueue_options      => enqueue_options,  
	                   message_properties   => message_properties,     
	                   payload       	=> dummyPageObj,               
 	                   msgid                => message_handle); 
       END IF;            
       COMMIT;
  END writePFObject;

  /* ============================================================================================================	
  |  Converts THE param names AND param VALUES, coming IN AS 2 seperate arrays, FROM THE JAVA layer,         | 
  |  INTO JTF_PF_PARAMS_TABLE                                                                                |
  |  This IS used TO construct THE JTF_PF_PAGE_OBJECT                                                        |
  ===============================================================================================================*/
  FUNCTION GetParams (paramNames JTF_VARCHAR2_TABLE_300, paramValues JTF_VARCHAR2_TABLE_4000, paramSz INTEGER)
  RETURN JTF_PF_PARAMS_TABLE IS
	params JTF_PF_PARAMS_TABLE := JTF_PF_PARAMS_TABLE();
  BEGIN
	FOR i IN 1..paramSz LOOP
	    params.EXTEND;
	    params(i) := JTF_PF_NVPAIR(paramNames(i),paramValues(i));
	END LOOP;
	RETURN params;
  END;

  /* ========================================================================
  |  Converts THE param names AND param VALUES,                             |
  |    coming IN AS an ARRAY OF NVPAIRS INTO a CLOB FOR clickstream support |
  ===========================================================================*/
  FUNCTION GetParamString(params JTF_PF_PARAMS_TABLE)
  RETURN CLOB IS
        paramCLOB       CLOB;
        paramV          VARCHAR(32767);
        nv              JTF_PF_NVPAIR;
        paramSz         NUMBER;
        psize           NUMBER;
        offset          NUMBER;
        i               NUMBER;
  BEGIN
        dbms_lob.createtemporary(paramCLOB,TRUE,DBMS_LOB.CALL);
        psize := 0;
        IF(params IS NULL) THEN
		RETURN paramCLOB;
	END IF;
        paramSz := params.COUNT;

        FOR i IN 1..paramSz LOOP
                nv := params(i);
                IF i <> 1 THEN
                        paramV := '&' || nv.NAME || '=' || nv.value;
                ELSE
                        paramV := nv.NAME || '=' || nv.value;
                END IF;
                IF paramV IS NOT NULL THEN
                        psize := length(paramV);
                        offset := DBMS_LOB.GETLENGTH(paramClob) + 1;
                        DBMS_LOB.WRITE(paramCLOB,psize,offset,paramV);
                END IF;
        END LOOP;
        RETURN paramCLOB;
  END;

  /* ========================================================================
  |  Converts THE param names AND param VALUES,                             |
  |    coming IN AS an ARRAY OF NVPAIRS INTO a CLOB FOR clickstream support |
  ==========================================================================*/
  FUNCTION GetCookieString(params JTF_PF_COOKIES_TABLE)
  RETURN CLOB IS
        paramCLOB       CLOB;
        paramV          VARCHAR(32767);
        nvs             JTF_PF_NVSTRIPLET;
        paramSz         NUMBER;
        psize           NUMBER;
        offset          NUMBER;
        i               NUMBER;
  BEGIN
        dbms_lob.createtemporary(paramCLOB,TRUE,DBMS_LOB.CALL);
        psize := 0;
        IF(params IS NULL) THEN
		RETURN paramCLOB;
        END IF;
        paramSz := params.COUNT;

        FOR i IN 1..paramSz LOOP
                nvs := params(i);
                IF i <> 1 THEN
                        paramV := ' ' || nvs.NAME || '=' || nvl(nvs.value, 'JTF_PF_SZ:'||nvs.length) || ';';
                ELSE
                        paramV := nvs.NAME || '=' || nvl(nvs.value, 'JTF_PF_SZ:'||nvs.length) || ';';
                END IF;
                IF paramV IS NOT NULL THEN
                        psize := length(paramV);
                        offset := DBMS_LOB.GETLENGTH(paramClob) + 1;
                        DBMS_LOB.WRITE(paramCLOB,psize,offset,paramV);
                END IF;
        END LOOP;
        RETURN paramCLOB;
  END;

  /* ============================================================================================================	
  |  Converts THE cookie names, cookie sizes  AND cokie VALUES, coming IN AS 3 seperate arrays,                 | 
  |  FROM THE JAVA layer, INTO JTF_PF_COOKIES_TABLE                                                             |
  |  This IS used TO construct THE JTF_PF_PAGE_OBJECT                                                           |
  ===============================================================================================================*/
  FUNCTION GetCookies (cookieNames JTF_VARCHAR2_TABLE_300, cookieValues JTF_VARCHAR2_TABLE_4000,
		cookieSizes JTF_NUMBER_TABLE, cookieSz INTEGER)
  RETURN JTF_PF_COOKIES_TABLE IS
	cookie JTF_PF_COOKIES_TABLE := JTF_PF_COOKIES_TABLE();
  BEGIN
	cookie.EXTEND(cookieSz);
        FOR i IN 1..cookieSz LOOP
            cookie(i) := JTF_PF_NVSTRIPLET(cookieNames(i),cookieValues(i),cookieSizes(i));
        END LOOP;
	RETURN cookie;    
  END;


  /*============================================================================================================	
  | Upload THE data IN AQ periodically TO THE JTF Repository                                                   |
  =============================================================================================================*/

    PROCEDURE uploadAllNewPfObjects IS --ang This proc is currently not being invoked anywhere
	pgObjects            JTF_PF_PAGE_OBJECT ;
	new_messages         BOOLEAN :=TRUE;
	dopt                 dbms_aq.dequeue_options_t;
	mprop                dbms_aq.message_properties_t;
	deq_msgid            RAW(16);
	no_messages          EXCEPTION;
	last_msg_in_jtf_rep  INTEGER;
	last_msg_to_upload   INTEGER;
	current_msg          INTEGER;
	QUERY                VARCHAR2(2000);
	PRAGMA               EXCEPTION_INIT(NO_MESSAGES,-25228);
	PRAGMA               AUTONOMOUS_TRANSACTION;
   BEGIN     
         SELECT max(a.pageobject.info.recid) INTO last_msg_in_jtf_rep FROM jtf_pf_repository a;
         -- select max(a.corrid) into last_msg_to_upload from JTF_PF_LOGGING_TABLE a; 
       
         IF  last_msg_in_jtf_rep IS NOT NULL THEN current_msg := last_msg_in_jtf_rep; END IF;

	 dopt.navigation:=dbms_aq.first_message;
         dopt.dequeue_mode := DBMS_AQ.BROWSE; 
         dopt.wait := 0;
	 WHILE (new_messages) LOOP
	  BEGIN 
                IF(current_msg IS NOT NULL) THEN 
                    current_msg := current_msg + 1;
                    IF (current_msg > last_msg_to_upload) THEN  new_messages := FALSE; END IF; 
                    dopt.correlation := current_msg; 
                END IF;

                dbms_aq.dequeue(queue_name=>qname,
			        dequeue_options=>dopt,
			        message_properties=> mprop,
			        payload => pgObjects,
			        msgid => deq_msgid);
                
		current_msg := mprop.correlation;
		dopt.navigation := dbms_aq.first_message;
	        dopt.wait := 0;
                INSERT INTO jtf_pf_repository( --ang no need to update this insert as the proc is not in use
			pageobject, object_version_number,
			created_by, creation_date,
			last_updated_by, last_update_date)
		VALUES (pgObjects, 0, 690, pgObjects.info.Day, 690, pgObjects.info.Timestamp);

		-- dbms_output.put_line('inserted ' || mprop.correlation);
	  EXCEPTION
	       WHEN NO_MESSAGES THEN
                  IF(current_msg IS NOT NULL) THEN 
                      current_msg := current_msg + 1;
                      IF(current_msg > last_msg_to_upload) THEN
   	                  -- dbms_output.put_line('No more messages to dequeue');
                          new_messages := FALSE;
			  COMMIT;
                      END IF; 
                      dopt.correlation := current_msg; 
                  END IF;
               WHEN OTHERS THEN
                   new_messages :=FALSE;
		   -- raise_application_error(-20101, SQLERRM); 
	           -- dbms_output.put_line(SQLERRM);
          END;
	 END LOOP;
   END ;

    -- This procedure is for migrating data from the JTF_PF_REPOSITORY (OLTP Stage Area)
    -- to the OLAP Tables (JTF_PF_ANON_ACTIVITY, JTF_PF_SES_ACTIVITY).
    PROCEDURE MIGRATE_DATA(timezone_offset IN NUMBER) IS
	today DATE;
    BEGIN
	SELECT trunc(sysdate) INTO today FROM dual;
	JTF_PF_SOA_MIGRATE_PKG.MIGRATE_LOGINS_DATA(timezone_offset);
	JTF_PF_SOA_MIGRATE_PKG.MIGRATE_RESP_DATA(timezone_offset);
	JTF_PF_SOA_MIGRATE_PKG.MIGRATE_FORMS_DATA(timezone_offset);
	migrate_data_raw;
	migrate_data_stats(today);
	COMMIT;
    END MIGRATE_DATA;

    PROCEDURE MIGRATE_DATA_STATS(today DATE) IS
    BEGIN
	IF (last_migrate_day IS NULL) THEN
	    SELECT min(x.day) INTO last_migrate_day FROM
            (SELECT max(day) AS day FROM JTF_PF_APP_SUMM
		     UNION ALL
		     SELECT max(day) AS day FROM JTF_PF_HOST_SUMM
		     UNION ALL
		     SELECT max(day) AS day FROM JTF_PF_PAGE_SUMM
		     UNION ALL 
		     SELECT max(day) AS day FROM JTF_PF_SESSION_SUMM
		     UNION ALL 
		     SELECT max(day) AS day FROM JTF_PF_USER_SUMM
			) x;
	END IF;
	IF (last_migrate_day IS NOT NULL) THEN
		--DELETE FROM JTF_PF_ANON_ACTIVITY WHERE day < last_migrate_day;
		--DELETE FROM JTF_PF_SES_ACTIVITY  WHERE day < last_migrate_day;
		DELETE FROM JTF_PF_APP_SUMM WHERE day >= last_migrate_day;
		DELETE FROM JTF_PF_HOST_SUMM WHERE day >= last_migrate_day;
		DELETE FROM JTF_PF_PAGE_SUMM WHERE day >= last_migrate_day;
		DELETE FROM JTF_PF_SESSION_SUMM WHERE (sessionid IS NULL and day >= last_migrate_day)
						or (sessionid IS NOT NULL and sessionid IN
							(select distinct sessionid from JTF_PF_SES_ACTIVITY where day >= last_migrate_day OR last_migrate_day IS NULL));
		DELETE FROM JTF_PF_USER_SUMM WHERE day >= last_migrate_day;
	END IF;
	
	INSERT INTO JTF_PF_APP_SUMM (day, cnt_pages_jtf, cnt_pages_oaf, cnt_pages_form, cnt_pages_all, cnt_flows, cnt_users, cnt_apps, cnt_resps, cnt_sessions, cnt_langs)
		(SELECT day, cnt_pages_jtf, cnt_pages_oaf, cnt_pages_form, cnt_pages_jtf+cnt_pages_oaf+cnt_pages_form, cnt_flows, cnt_users, cnt_apps, cnt_resps, cnt_sessions, cnt_langs 
		 FROM JTF_PF_APP_SUMMARY_VL 
		 WHERE day >= last_migrate_day OR last_migrate_day IS NULL
		 );
	INSERT INTO JTF_PF_HOST_SUMM (day, servername, serverport, jservs, sum_exect_jtf, sum_exect_oaf, pagehits_jtf, pagehits_oaf, pagehits_all, fails, pages, badpages) 
		(SELECT day, NVL(servername, 'N/A'), NVL(serverport, -1), jservs, sum_exect_jtf, sum_exect_oaf, pagehits_jtf, pagehits_oaf, pagehits_jtf+pagehits_oaf, fails, pages, badpages 
		 FROM JTF_PF_HOST_SUMMARY_VL 
		 WHERE day >= last_migrate_day OR last_migrate_day IS NULL
		);
	INSERT INTO JTF_PF_PAGE_SUMM (day, pagename, tech_stack, cnt_pages, cnt_ses, ucnt_ses, ucnt_users, ucnt_apps, ucnt_resps, ucnt_langs,
			sum_exect, sum_thinkt, cnt_thinkt, startt, endt, cnt_fail, cnt_forward)
		(SELECT day, pagename, tech_stack, cnt_pages, cnt_ses, ucnt_ses, ucnt_users, ucnt_apps, ucnt_resps, ucnt_langs,
			sum_exect, sum_thinkt, cnt_thinkt, startt, endt, cnt_fail, cnt_forward 
		 FROM JTF_PF_PAGE_SUMMARY_VL 
		 WHERE day >= last_migrate_day OR last_migrate_day IS NULL
		);
	INSERT INTO JTF_PF_SESSION_SUMM (day, seqid, sessionid, user_name, userid, sum_exect_jtf, sum_exect_oaf, sum_exect_form, sum_thinkt_jtf, sum_thinkt_oaf, sum_thinkt_form,
			 cnt_pages_jtf, cnt_pages_oaf, cnt_pages_form, cnt_pages_all, ucnt_pages, ucnt_flows, ucnt_users, ucnt_apps, ucnt_resps, ucnt_langs, startt, endt, cnt_fail)
		(SELECT  day, seqid, sessionid, user_name, userid, sum_exect_jtf, sum_exect_oaf, sum_exect_form, sum_thinkt_jtf, sum_thinkt_oaf, sum_thinkt_form,
			cnt_pages_jtf, cnt_pages_oaf, cnt_pages_form, cnt_pages_jtf+cnt_pages_oaf+cnt_pages_form, ucnt_pages, ucnt_flows, ucnt_users, ucnt_apps, ucnt_resps, ucnt_langs, startt, endt, cnt_fail
		 FROM JTF_PF_SESSION_SUMMARY_VL 
		 WHERE (sessionid IS NULL and day >= last_migrate_day)
			or (sessionid IS NOT NULL and sessionid IN
				(select distinct sessionid from JTF_PF_SES_ACTIVITY where day >= last_migrate_day OR last_migrate_day IS NULL))
		);
	INSERT INTO JTF_PF_USER_SUMM (day, user_name, userid, sum_exect_jtf, sum_exect_oaf, sum_exect_form, sum_thinkt_jtf, sum_thinkt_oaf, sum_thinkt_form,
			cnt_pages_jtf, cnt_pages_oaf, cnt_pages_form, cnt_pages_all, ucnt_ses, ucnt_pages, ucnt_apps, ucnt_resps, ucnt_langs, startt, endt, cnt_fail)
		(SELECT day, user_name, userid, sum_exect_jtf, sum_exect_oaf, sum_exect_form, sum_thinkt_jtf, sum_thinkt_oaf, sum_thinkt_form,
			cnt_pages_jtf, cnt_pages_oaf, cnt_pages_form, cnt_pages_jtf+cnt_pages_oaf+cnt_pages_form, ucnt_ses, ucnt_pages, ucnt_apps, ucnt_resps, ucnt_langs, startt, endt, cnt_fail
		 FROM JTF_PF_USER_SUMMARY_VL 
		 WHERE day >= last_migrate_day OR last_migrate_day IS NULL
		);
	last_migrate_day := today;
    END MIGRATE_DATA_STATS;

    PROCEDURE MIGRATE_DATA_RAW IS
	v_SQLString VARCHAR2(300);  

	CURSOR po_Cursor(starting_po IN INTEGER) IS
		SELECT x.pageobject, x.tech_stack 
		FROM JTF_PF_REPOSITORY x
		WHERE x.pageobject.info.RecId > starting_po
		ORDER BY x.pageobject.ses.SessionId, x.pageobject.jsp.StartTime;

	CURSOR cur_val IS SELECT nvl(max_po,-100000000000), nvl(ses_seqid,0), nvl(anon_seqid,0) FROM JTF_PF_SEQ_VL;

	nextpo JTF_PF_PAGE_OBJECT;
	currpo JTF_PF_PAGE_OBJECT;
	thinkT INTEGER;
	seqcnt1 INTEGER;
	seqcnt2 INTEGER;
	maxpo  INTEGER;
	currtechstack varchar2(20);
	nexttechstack VARCHAR2(20);

    BEGIN
	OPEN cur_val;
	FETCH cur_val INTO maxpo, seqcnt2, seqcnt1;
	CLOSE cur_val;

	currpo := NULL;

	OPEN po_Cursor(maxpo);
	LOOP
	    FETCH po_Cursor INTO nextpo, nexttechstack; 
	    -- if record exists in the cursor (previous iteration)
	    IF currpo IS NOT NULL THEN
			-- for anonymous activity
			IF currpo.ses IS NULL THEN
                            IF currpo.jsp IS NOT NULL AND currpo.loc IS NOT NULL AND currpo.info IS NOT NULL THEN
		      	        seqcnt1 := seqcnt1 - 1;
				INSERT INTO JTF_PF_ANON_ACTIVITY(
	                                SEQID,
	                                DAY,
	                                TECH_STACK, 
	                                TIMESTAMP,
	                                SERVERNAME,
	                                SERVERPORT,
	                                JSERVPORT,
	                                FLOWID,
	                                SESSIONID,
	                                USERID,
	                                APPID,
	                                RESPID,
	                                LANGID,
	                                STARTT,
	                                PAGENAME,
	                                STATUSCODE,
	                                EXECT,
	                                THINKT,
	                                PO,
	                                OBJECT_VERSION_NUMBER,
	                                CREATED_BY,
	                                CREATION_DATE,
	                                LAST_UPDATED_BY,
	                                LAST_UPDATE_DATE
				) VALUES(
					seqcnt1,
					currpo.info.day,
					currtechstack, 
					currpo.info.timestamp, 
					currpo.loc.servername,
					currpo.loc.serverport,
					currpo.loc.jservport,
					null,
					null,
					null,
					null,
					null,
					null,
					NVL(currpo.jsp.starttime, -1), -- ANG - Remove NVL condition, still what to do when starttime is null
					NVL(currpo.jsp.NAME, 'N/A'), -- ANG - Remove NVL condition, again there are records in repository table where the value for name coln is null. How should this be handled?
					NVL(currpo.jsp.statusCode, -1), -- ANG - need to get rid of NVL condition
					NVL(currpo.jsp.executionTime, -1), -- ANG - need to get rid of NVL condition
					thinkT,
					currpo.info.Recid,
					0,690,currpo.info.day,690,currpo.info.timestamp);
		             END IF;	
			ELSE
				-- for session activity
		    		thinkT := NULL;
				IF NOT(currpo.jsp.statusCode = -200) AND currpo.ses.SessionId = nextpo.ses.SessionId AND NOT(po_Cursor%NOTFOUND) THEN
				    thinkT := (nextpo.jsp.StartTime - (currpo.jsp.StartTime + currpo.jsp.executionTime));
				    IF thinkT IS NOT NULL AND thinkT <= 0 THEN
					thinkT := NULL;
				    END IF;
				END IF;
                            IF          currpo.jsp               IS NOT NULL 
                                AND     currpo.loc               IS NOT NULL 
                                AND     currpo.info              IS NOT NULL 
			 	AND	currtechstack            IS NOT NULL 
			        AND	currpo.info.day          IS NOT NULL
				AND     currpo.info.timestamp    IS NOT NULL 
				AND     currpo.info.Recid        IS NOT NULL
				AND 	currpo.ses.sessionid     IS NOT NULL
				AND 	currpo.ses.userid        IS NOT NULL
				AND 	currpo.ses.appid         IS NOT NULL
				AND 	currpo.ses.respid        IS NOT NULL
				AND 	currpo.ses.langid        IS NOT NULL
				AND 	currpo.jsp.starttime     IS NOT NULL
				AND 	currpo.jsp.NAME          IS NOT NULL
				AND 	currpo.jsp.statusCode    IS NOT NULL
				AND 	currpo.jsp.executionTime IS NOT NULL
                            THEN
				seqcnt2 := seqcnt2 + 1;
				INSERT INTO JTF_PF_SES_ACTIVITY(
	                                SEQID,
	                                DAY,
	                                TECH_STACK, 
	                                TIMESTAMP,
	                                SERVERNAME,
	                                SERVERPORT,
	                                JSERVPORT,
	                                FLOWID,
	                                SESSIONID,
	                                USERID,
	                                APPID,
	                                RESPID,
	                                LANGID,
	                                STARTT,
	                                PAGENAME,
	                                STATUSCODE,
	                                EXECT,
	                                THINKT,
	                                PO,
	                                OBJECT_VERSION_NUMBER,
	                                CREATED_BY,
	                                CREATION_DATE,
	                                LAST_UPDATED_BY,
	                                LAST_UPDATE_DATE
				) VALUES(
					seqcnt2,
					currpo.info.day,
					currtechstack, 
					currpo.info.timestamp, 
					currpo.loc.servername,
					currpo.loc.serverport,
					currpo.loc.jservport,
					null,
					currpo.ses.sessionid,
					currpo.ses.userid,
					currpo.ses.appid,
					currpo.ses.respid,
					currpo.ses.langid,
					currpo.jsp.starttime,
					currpo.jsp.NAME,
					currpo.jsp.statusCode,
					currpo.jsp.executionTime,
					thinkT,
					currpo.info.Recid,
					0,690,currpo.info.day,690,currpo.info.timestamp);
		             END IF;	
			END IF;
	    END IF;
	    EXIT WHEN po_Cursor%NOTFOUND;
	    currpo := nextpo;
	    currtechstack := nexttechstack;
	END LOOP;
	CLOSE po_Cursor;
    END MIGRATE_DATA_RAW;

   /*============================================================================================================
    | Wrapper FOR migrate_data TO be called BY Concurrent Manager
   ============================================================================================================*/
   PROCEDURE synchronize_pageflow_data
   (ERRBUF                    OUT VARCHAR2,
   RETCODE                   OUT NUMBER
   )
   IS
   BEGIN

     --call migrate api
     JTF_PF_CONV_PKG.migrate_data(0);

    EXCEPTION
    WHEN OTHERS
    THEN
       RETCODE := 2;
       ERRBUF := sqlcode||':'||sqlerrm;
       fnd_file.put_line(fnd_file.log, 'JTF_PF_CONV_PKG.synchronize_pageflow_data failed ' || sqlcode||':'||sqlerrm);
   END synchronize_pageflow_data;

  FUNCTION GetParamNVs (po_id INTEGER)
  RETURN JTF_VARCHAR2_TABLE_4000 IS
        params	JTF_PF_PARAMS_TABLE;
        paramSz	NUMBER;
	nv	JTF_PF_NVPAIR;
	pname	JTF_VARCHAR2_TABLE_4000 := JTF_VARCHAR2_TABLE_4000();
	CURSOR cur(poid IN INTEGER) IS
		SELECT x.pageobject.params
		FROM JTF_PF_REPOSITORY x
		WHERE x.pageobject.info.RecId = poid;
  BEGIN
	OPEN cur(po_id);
	FETCH cur INTO params;
	IF cur%NOTFOUND THEN
		CLOSE cur;
		RETURN NULL;
	END IF;
	CLOSE cur;

	IF params IS NULL THEN
		pname.EXTEND(1);
		pname(1) := '';
		RETURN pname;
	END IF;

	paramSz := params.COUNT;

	pname.EXTEND(paramSz * 2);
        FOR i IN 1..paramSz LOOP
	    nv := params(i);
	    pname(2 * i - 1) := nv.NAME;
	    pname(2 * i) := nv.value;
        END LOOP;
	RETURN pname;
  END;

  FUNCTION GetParamNames (params JTF_PF_PARAMS_TABLE, paramSz INTEGER)
  RETURN JTF_VARCHAR2_TABLE_300 IS
	nv    JTF_PF_NVPAIR;
	pname JTF_VARCHAR2_TABLE_300 := JTF_VARCHAR2_TABLE_300();
  BEGIN
	pname.EXTEND(paramSz);
        FOR i IN 1..paramSz LOOP
	    nv := params(i);
	    pname(i) := nv.NAME;
        END LOOP;
	RETURN pname;
  END;
 
  FUNCTION GetParamValues (params JTF_PF_PARAMS_TABLE, paramSz INTEGER)
  RETURN JTF_VARCHAR2_TABLE_4000 IS
	nv    JTF_PF_NVPAIR;
	pval JTF_VARCHAR2_TABLE_4000 := JTF_VARCHAR2_TABLE_4000();
  BEGIN
	pval.EXTEND(paramSz);
	FOR i IN 1..paramSz LOOP
	    nv := params(i);
	    pval(i) := nv.value;
	END LOOP;
  END;

  PROCEDURE CLEAN_DATA(START_DATE DATE) IS
    TYPE RECTABTYPE IS TABLE OF NUMBER  INDEX BY BINARY_INTEGER;
    RECTABTYPE1 RECTABTYPE;
    CURSOR EBIZ_DATA IS
     SELECT X.PAGEOBJECT.INFO.RECID FROM JTF_PF_REPOSITORY X WHERE 
     X.LAST_UPDATE_DATE <= START_DATE;
  BEGIN
     OPEN EBIZ_DATA;
     LOOP
        FETCH EBIZ_DATA BULK COLLECT INTO RECTABTYPE1 LIMIT 1000;
	IF RECTABTYPE1.COUNT > 0  THEN 
	  FORALL I IN RECTABTYPE1.FIRST .. RECTABTYPE1.LAST
          DELETE FROM JTF_PF_REPOSITORY X WHERE X.PAGEOBJECT.INFO.RECID = RECTABTYPE1(I);
	END IF;
       EXIT WHEN EBIZ_DATA%NOTFOUND;
     END LOOP;
    RECTABTYPE1.DELETE;
    CLOSE EBIZ_DATA;
    COMMIT;
  END;

  PROCEDURE PURGE_DATA(start_date IN DATE) IS
	PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
        --dbms_output.put_line('purge data ');
        CLEAN_DATA(START_DATE);	
	DELETE FROM JTF_PF_SES_ACTIVITY WHERE DAY <= START_DATE; 
        DELETE FROM JTF_PF_ANON_ACTIVITY	WHERE DAY <= START_DATE;
	DELETE FROM JTF_PF_APP_SUMM WHERE DAY <= START_DATE;
        DELETE FROM JTF_PF_HOST_SUMM WHERE DAY <= START_DATE;
	DELETE FROM JTF_PF_PAGE_SUMM WHERE DAY <= START_DATE;
        DELETE FROM JTF_PF_SESSION_SUMM WHERE DAY <= START_DATE;
	DELETE FROM JTF_PF_USER_SUMM WHERE DAY <= START_DATE;
	COMMIT;
  END;

  PROCEDURE PURGE_DATA(ERRBUF OUT VARCHAR2, RETCODE OUT NUMBER, start_date IN DATE) IS
	PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
        PURGE_DATA(START_DATE);
  EXCEPTION
    WHEN OTHERS
    THEN
       RETCODE := 2;
       ERRBUF := sqlcode||':'||sqlerrm;
       fnd_file.put_line(fnd_file.log, 'JTF_PF_CONV_PKG.PURGE_DATA failed ' || sqlcode||':'||sqlerrm);
  END;


  PROCEDURE MULTIPLY_DATA(days NUMBER) IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	CURSOR cur IS
		SELECT MAX(x.pageobject.ses.sessionid) + 3
		FROM JTF_PF_REPOSITORY_TMP x;
	max_sessionid INTEGER;
  BEGIN
	DELETE FROM JTF_PF_REPOSITORY_TMP;
	DELETE FROM JTF_PF_REPOSITORY x WHERE x.pageobject.info.day > sysdate;
	COMMIT;

	INSERT INTO JTF_PF_REPOSITORY_TMP(pageobject, object_version_number, created_by, creation_date, last_updated_by, last_update_date, last_update_login, security_group_id, tech_stack)
		(SELECT pageobject, object_version_number, created_by, creation_date, last_updated_by, last_update_date, last_update_login, security_group_id, tech_stack FROM JTF_PF_REPOSITORY x
		WHERE
				x.pageobject.info.day > sysdate - 1
			AND	x.pageobject.info.day < sysdate);
	COMMIT;

	OPEN cur;
	FETCH cur INTO max_sessionid;
	IF(cur%NOTFOUND OR max_sessionid IS NULL) THEN
		max_sessionid := 100000;
	END IF;
	CLOSE cur;

	FOR i IN 1..days LOOP
		UPDATE JTF_PF_REPOSITORY_TMP x
		SET
			x.pageobject.info.day = x.pageobject.info.day + 1,
			x.pageobject.info.timestamp = x.pageobject.info.timestamp + 1,
			x.pageobject.jsp.starttime = x.pageobject.jsp.starttime + 1000 * 60 * 60 * 24;
		COMMIT;

		UPDATE JTF_PF_REPOSITORY_TMP x
		SET
			x.pageobject.ses.sessionid = decode(x.pageobject.ses.sessionid,
								NULL,x.pageobject.ses.sessionid,
								-1,x.pageobject.ses.sessionid,
								x.pageobject.ses.sessionid - max_sessionid)
		WHERE
			x.pageobject.ses IS NOT NULL;
		COMMIT;

		INSERT INTO JTF_PF_REPOSITORY (pageobject, object_version_number, created_by, creation_date, last_updated_by, last_update_date, last_update_login, security_group_id, tech_stack)
            (SELECT pageobject, object_version_number, created_by, creation_date, last_updated_by, last_update_date, last_update_login, security_group_id, tech_stack FROM JTF_PF_REPOSITORY_TMP);
		COMMIT;
	END LOOP;
  END;
-- ##### 20100217 –{”Ô#1609‘Î‰ž START #####
--  Function GROUP_CONCAT ( list IN JTF_PF_TABLETYPE, separator VARCHAR2)
--  RETURN  VARCHAR2 IS
--    ret VARCHAR2(1000) :='';
--  BEGIN
--    IF (list.COUNT > 0) THEN
--      FOR j IN list.FIRST..list.LAST  LOOP
--        IF j = 1 THEN
--          ret := list(j);
--        ELSE
--          ret := ret || separator || list(j);
--        END IF;
--      END LOOP;
--      RETURN ret;
--    ELSE
--      RETURN ret;
--    END IF;
--  END;
  Function GROUP_CONCAT ( list IN JTF_PF_TABLETYPE, separator VARCHAR2)
  RETURN VARCHAR2 IS
    ret VARCHAR2(4000) :='';
  BEGIN
    IF (list.COUNT > 0) THEN
      FOR j IN list.FIRST..list.LAST LOOP
        IF j = 1 THEN
          ret := list(j);
        ELSE
          --9365233, increased variable to 4000 and protected against an overrun
          IF lengthb(ret || separator || list(j)) < 4000 then
            ret := ret || separator || list(j);
          END IF;
        END IF;
      END LOOP;
      RETURN ret;
    ELSE
      RETURN ret;
    END IF;
  END;
-- ##### 20100217 –{”Ô#1609‘Î‰ž END #####
END;
/
COMMIT;
--show errors;
EXIT;
