CREATE OR REPLACE PACKAGE BODY XXCOI001A02R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI001A02R(body)
 * Description      : �w�肳�ꂽ�����ɕR�Â����Ɋm�F���̃��X�g���o�͂��܂��B
 * MD.050           : ���ɖ��m�F���X�g MD050_COI_001_A02
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_output_base        �o�͋��_�擾 (A-2)
 *  ins_storage_info       �f�[�^�o�^ (A-4)
 *  exec_svf_conc          SVF�R���J�����g�̋N�� (A-5)
 *  get_table_lock         ���[�N�e�[�u�����b�N�擾(A-7)
 *  del_storage_info       �f�[�^�폜 (A-8)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/08    1.0   S.Moriyama       main�V�K�쐬
 *  2009/03/05    1.1   H.Wada           ��Q�ԍ� #034 ���������C��
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  get_output_type_expt      EXCEPTION;                                -- �o�͋敪���̎擾�G���[
  prm_date_expt             EXCEPTION;                                -- ���t�p�����[�^�s���G���[
  exec_svfapi_expt          EXCEPTION;                                -- SVF���[���ʊ֐��G���[
  get_tbl_lock_expt         EXCEPTION;                                -- ���[�N�e�[�u�����b�N�擾�G���[
  PRAGMA EXCEPTION_INIT( get_tbl_lock_expt, -54 );                    -- ���b�N�擾��O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCOI001A02R';          -- �p�b�P�[�W��
  cv_application   CONSTANT VARCHAR2(100) := 'XXCOI';                 -- �A�v���P�[�V������
  cv_yes           CONSTANT VARCHAR2(100) := 'Y';                     -- �Œ�l'Y'
  cv_no            CONSTANT VARCHAR2(100) := 'N';                     -- �Œ�l'N'
--
  cv_output_type   CONSTANT VARCHAR2(100) := 'XXCOI1_UNCONFIRMED_LIST_DIV'; -- ���ɖ��m�F���X�g�o�͋敪
  cv_list_type     CONSTANT VARCHAR2(100) := 'XXCOI1_STOCKED_VOUCH_DIV'; -- ���Ɋm�F�`�[�敪
  cv_prf_org_code  CONSTANT VARCHAR2(100) := 'XXCOI1_ORGANIZATION_CODE'; -- �݌ɑg�D
--
  cv_msg_00008     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00008';      -- 0�����b�Z�[�W
  cv_msg_00010     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00010';      -- API�G���[���b�Z�[�W
  cv_msg_10036     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10036';      -- �p�����[�^���_�l���b�Z�[�W
  cv_msg_10191     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10191';      -- �p�����[�^�o�͋敪���b�Z�[�W
  cv_msg_10192     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10192';      -- �p�����[�^���t�i���j���b�Z�[�W
  cv_msg_10193     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10193';      -- �p�����[�^���t�i���j���b�Z�[�W
  cv_msg_10240     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10240';      -- ���t�s�����b�Z�[�W
  cv_msg_10156     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10156';      -- ���b�N�擾�G���[
  cv_msg_10337     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10337';      -- ���t�召�֌W�s�����b�Z�[�W
--
  cv_tok_base      CONSTANT VARCHAR2(100) := 'BASE_CODE';             -- �g�[�N���uBASE_CODE�v
  cv_tok_output    CONSTANT VARCHAR2(100) := 'P_OUTPUT_TYPE';         -- �g�[�N���uP_OUTPUT_TYPE�v
  cv_tok_from      CONSTANT VARCHAR2(100) := 'P_DATE_FROM';           -- �g�[�N���uP_DATE_FROM�v
  cv_tok_to        CONSTANT VARCHAR2(100) := 'P_DATE_TO';             -- �g�[�N���uP_DATE_TO�v
  cv_tok_api       CONSTANT VARCHAR2(100) := 'API_NAME';              -- �g�[�N���uAPI_NAME�v
  cv_api_coicmn    CONSTANT VARCHAR2(100) := 'GET_MEANING';           -- �g�[�N���uAPI�Z�b�g���e�v
  cv_api_belogin   CONSTANT VARCHAR2(100) := 'GET_BELONGING_BASE';    -- �g�[�N���uAPI�Z�b�g���e�v
  cv_api_svfcmn    CONSTANT VARCHAR2(100) := 'SUBMIT_SVF_REQUEST';    -- �g�[�N���uAPI�Z�b�g���e�v
--
  cv_frm_nm        CONSTANT VARCHAR2(100) := 'XXCOI001A02S.xml';      -- �t�H�[���l���t�@�C����
  cv_vrq_nm        CONSTANT VARCHAR2(100) := 'XXCOI001A02S.vrq';      -- �N�G���[�l���t�@�C����
  cv_pdf_nm        CONSTANT VARCHAR2(100) := 'XXCOI001A02S.pdf';      -- PDF�t�@�C����
  cv_svf_id        CONSTANT VARCHAR2(100) := 'XXCOI001A02S';          -- ���[ID
  cv_output_mode   CONSTANT VARCHAR2(1) := '1';                       -- �o�͋敪(PDF�o��)
--
  cv_slip_type_1   CONSTANT VARCHAR2(10) := '10';                     -- �H�����
  cv_slip_type_2   CONSTANT VARCHAR2(10) := '20';                     -- ���_�ԓ���
  cv_output_div_10 CONSTANT VARCHAR2(10) := '10';                     -- ���Ɋm�F�����{
  cv_output_div_20 CONSTANT VARCHAR2(10) := '20';                     -- ���o�ɍ��ٗL
  cv_output_div_30 CONSTANT VARCHAR2(10) := '30';                     -- �S�f�[�^�Ώ�
  cv_summary_kbn   CONSTANT VARCHAR2(1) := '1';                       -- �f�[�^���:�T�}��
  cv_detail_kbn    CONSTANT VARCHAR2(1) := '2';                       -- �f�[�^���:�ڍ�
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �o�͋��_���R�[�h�^
  TYPE gr_output_base_rec IS RECORD(                                  -- �o�͑Ώۋ��_���i�[���R�[�h
      base_code              xxcoi_base_info_v.base_code%TYPE
    , base_name              xxcoi_base_info_v.base_short_name%TYPE
  );
  TYPE gt_output_base_ttype                                           -- �o�͑Ώۋ��_�i�[�p�e�[�u���ϐ�
  IS TABLE OF gr_output_base_rec INDEX BY BINARY_INTEGER;
--
  gt_base_tab                gt_output_base_ttype;                    -- �o�͋��_���i�[�p
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gt_output_type_meaning    fnd_lookup_values.meaning%TYPE;           -- �o�͋敪����
  gv_date_from              VARCHAR2(10);                             -- ���t�i���j
  gv_date_to                VARCHAR2(10);                             -- ���t�i���j
  gn_output_base_num        NUMBER;                                   -- �o�͋��_��
  gn_output_base_cnt        NUMBER;                                   -- �o�͋��_�J�E���^
  gn_output_rec_num         NUMBER;                                   -- �o�̓��R�[�h����
  gn_output_rec_cnt         NUMBER;                                   -- �o�̓��R�[�h�J�E���^
  gt_base_code              xxcoi_storage_information.base_code%TYPE; -- ���_�R�[�h
  gt_base_name              xxcoi_base_info_v.base_short_name%TYPE;   -- ���_��
  gv_zero_message           VARCHAR2(200);                            -- 0�����b�Z�[�W�i�[
--
  CURSOR storage_info_cur(
             iv_base_code   VARCHAR2
           , iv_output_type VARCHAR2
           , iv_date_from   VARCHAR2
           , iv_date_to     VARCHAR2)
  IS
  SELECT xsi.base_code                            AS base_code        -- ���_�R�[�h
        ,SUBSTRB(hca_b.account_name,1,8)          AS base_name        -- ���_��
        ,xsi.slip_date                            AS slip_date        -- �`�[���t
        ,xsi.slip_num                             AS slip_num         -- �`�[�ԍ�
        ,xsi.check_warehouse_code                 AS check_warehouse_code
                                                                      -- �q�ɃR�[�h
        ,xsi.item_code                            AS item_code        -- �q�i�ڃR�[�h
        ,SUBSTRB(ximb.item_short_name,1,20)       AS item_name        -- �i�ڗ���
        ,CASE WHEN xsi.summary_data_flag = cv_yes
              THEN NULL ELSE xsi.taste_term END   AS taste_term       -- �ܖ�����
        ,CASE WHEN xsi.summary_data_flag = cv_yes
              THEN NULL ELSE xsi.difference_summary_code END          -- �H��ŗL�L��
                                                  AS factory_unique_mark
        ,xsi.case_in_qty                          AS case_in_qty      -- ����
        ,xsi.ship_case_qty                        AS ship_case_qty    -- �o�ɐ��ʃP�[�X��
        ,xsi.ship_singly_qty                      AS ship_singly_qty  -- �o�ɐ��ʃo����
        ,xsi.ship_summary_qty                     AS ship_summary_qty -- �o�ɐ��ʑ��o����
        ,CASE WHEN xsi.summary_data_flag = cv_yes
              THEN NVL(xsi.check_case_qty,0) ELSE NULL END            -- �m�F���ʃP�[�X��
                                                  AS check_case_qty
        ,CASE WHEN xsi.summary_data_flag = cv_yes
              THEN NVL(xsi.check_singly_qty,0) ELSE NULL END          -- �m�F���ʃo����
                                                  AS check_singly_qty
        ,CASE WHEN xsi.summary_data_flag = cv_yes
              THEN NVL(xsi.check_summary_qty,0) ELSE NULL END         -- �m�F���ʑ��o����
                                                  AS check_summary_qty
        ,CASE WHEN xsi.summary_data_flag = cv_yes
              THEN NVL(xsi.ship_summary_qty,0) - NVL(xsi.check_summary_qty,0) ELSE NULL END -- �������v����
                                                  AS difference_summary_qty
        ,CASE WHEN xsi.summary_data_flag = cv_yes
              THEN flv.meaning ELSE NULL END      AS slip_type        -- �`�[�敪
        ,CASE WHEN xsi.summary_data_flag = cv_yes
              THEN xsi.ship_base_code ELSE NULL END                   -- �o�ɋ��_�R�[�h
                                                  AS ship_base_code
        ,CASE WHEN xsi.summary_data_flag = cv_yes
              THEN ship_base.ship_base_name ELSE NULL END AS ship_base_name
                                                                      -- �o�ɋ��_��
        ,CASE WHEN xsi.summary_data_flag = cv_yes
              THEN cv_summary_kbn ELSE cv_detail_kbn END AS data_type -- �f�[�^���
  FROM   xxcoi_storage_information xsi
        ,hz_cust_accounts  hca_b                                      -- �ڋq�}�X�^�i���_�j
        ,ic_item_mst_b     iimb                                       -- OPM�i�ڃ}�X�^�i�q�j
        ,xxcmn_item_mst_b  ximb                                       -- OPM�i�ڃA�h�I���}�X�^
        ,fnd_lookup_values flv                                        -- �N�C�b�N�R�[�h�}�X�^
        ,(SELECT   xsi.transaction_id
                 , ship_base.ship_base_name
          FROM     (SELECT   xsi.transaction_id
                           , hca.account_name ship_base_name
                    FROM     xxcoi_storage_information xsi
                           , hz_cust_accounts hca
                    WHERE    xsi.ship_base_code = hca.account_number
                    AND      xsi.slip_type = cv_slip_type_2
                    UNION
                    SELECT   xsi.transaction_id
                           , mil.description ship_base_name
                    FROM     xxcoi_storage_information xsi
                           , mtl_item_locations mil
                    WHERE    xsi.ship_base_code = mil.segment1
                    AND      xsi.slip_type = cv_slip_type_1
                   ) ship_base
                   , xxcoi_storage_information xsi
          WHERE  xsi.transaction_id = ship_base.transaction_id
        )ship_base
        ,(SELECT xsi.slip_num
          FROM   xxcoi_storage_information xsi
          WHERE  xsi.base_code = iv_base_code
          AND    TRUNC(xsi.slip_date) BETWEEN TO_DATE(iv_date_from,'YYYY/MM/DD') AND TO_DATE(iv_date_to,'YYYY/MM/DD')
          AND    xsi.summary_data_flag = cv_yes
          AND   ((iv_output_type = cv_output_div_10
                  AND xsi.store_check_flag = cv_no
                 )
                 OR(iv_output_type = cv_output_div_20
                    AND xsi.ship_summary_qty <> xsi.check_summary_qty
                   )
                 OR iv_output_type = cv_output_div_30
                )
          UNION
          SELECT xsi1.slip_num
          FROM   xxcoi_storage_information xsi1
                ,xxcoi_storage_information xsi2
          WHERE  xsi1.base_code = iv_base_code
          AND    TRUNC(xsi1.slip_date) BETWEEN TO_DATE(iv_date_from,'YYYY/MM/DD') AND TO_DATE(iv_date_to,'YYYY/MM/DD')
          AND    xsi1.summary_data_flag = cv_yes
          AND    xsi1.slip_num = xsi2.slip_num
          AND    TRUNC(xsi1.slip_date) <> TRUNC(xsi2.slip_date)
          AND    iv_output_type = cv_output_div_20
        )xsii
  WHERE  xsi.base_code = hca_b.account_number
  AND    xsi.slip_type = flv.lookup_code
  AND    iimb.item_id = ximb.item_id
  AND    xsi.item_code = iimb.item_no
  AND    xsi.slip_num = xsii.slip_num
  AND    flv.enabled_flag = cv_yes
  AND    flv.language = userenv('LANG')
  AND    flv.lookup_type = cv_list_type
  AND    TRUNC(SYSDATE) BETWEEN TRUNC(flv.start_date_active) AND NVL(flv.end_date_active,TRUNC(SYSDATE))
  AND    xsi.transaction_id = ship_base.transaction_id
  ORDER BY  xsi.slip_num
           ,xsi.slip_date
           ,xsi.base_code
           ,xsi.check_warehouse_code
           ,xsi.item_code
           ,xsi.slip_type
           ,xsi.summary_data_flag DESC;
--
  storage_info_rec storage_info_cur%ROWTYPE;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      iv_base_code   IN VARCHAR2                                      -- 1.���_�R�[�h
    , iv_output_type IN VARCHAR2                                      -- 2.�o�͋敪
    , iv_date_from   IN VARCHAR2                                      -- 3.�o�͓��t�i���j
    , iv_date_to     IN VARCHAR2                                      -- 4.�o�͓��t�i���j
    , ov_errbuf     OUT VARCHAR2                                      -- 5.�G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2                                      -- 6.���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2 )                                    -- 7.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_org_code               VARCHAR2(200);
    ld_date_from              DATE;
    ld_date_to                DATE;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    --�R���J�����g�p�����[�^�o��
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                    , iv_name         => cv_msg_10036
                    , iv_token_name1  => cv_tok_base
                    , iv_token_value1 => iv_base_code
                   );
    fnd_file.put_line(
       which => fnd_file.log
      ,buff  => gv_out_msg
    );
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                    , iv_name         => cv_msg_10191
                    , iv_token_name1  => cv_tok_output
                    , iv_token_value1 => iv_output_type
                   );
    fnd_file.put_line(
       which => fnd_file.log
      ,buff  => gv_out_msg
    );
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                    , iv_name         => cv_msg_10192
                    , iv_token_name1  => cv_tok_from
                    , iv_token_value1 => iv_date_from
                   );
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff => gv_out_msg
    );
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                    , iv_name         => cv_msg_10193
                    , iv_token_name1  => cv_tok_to
                    , iv_token_value1 => iv_date_to
                   );
    fnd_file.put_line(
       which => fnd_file.log
      ,buff  => gv_out_msg
    );
--
    --==============================================================
    --�p�����[�^���t�i���j�w��`�F�b�N
    --==============================================================
    gv_date_from := SUBSTRB(iv_date_from,1,10);
--
    IF (iv_date_to IS NULL) THEN
      gv_date_to := TO_CHAR(SYSDATE,'YYYY/MM/DD');
    ELSE
      gv_date_to := SUBSTRB(iv_date_to,1,10);
    END IF;
--
    BEGIN
      SELECT TO_DATE(gv_date_from,'YYYY/MM/DD')
            ,TO_DATE(gv_date_to,'YYYY/MM/DD')
      INTO   ld_date_from
            ,ld_date_to
      FROM   DUAL;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_10240
                     );
        lv_errbuf := lv_errmsg;
        RAISE prm_date_expt;
    END;
--
    IF ( TO_DATE(SUBSTRB(iv_date_from,1,10),'YYYY/MM/DD') > TO_DATE(gv_date_to,'YYYY/MM/DD') ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_msg_10337
                   );
      lv_errbuf := lv_errmsg;
      RAISE prm_date_expt;
    END IF;
--
    --==============================================================
    --�p�����[�^�o�͋敪���o�͋敪���̂��擾
    --==============================================================
    gt_output_type_meaning := xxcoi_common_pkg.get_meaning(
                                  iv_lookup_type => cv_output_type
                                , iv_lookup_code => iv_output_type
                              );
    IF (gt_output_type_meaning IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_msg_00010
                     , iv_token_name1  => cv_tok_api
                     , iv_token_value1 => cv_api_coicmn
                   );
      lv_errbuf := lv_errmsg;
      RAISE get_output_type_expt;
    END IF;
  EXCEPTION
    WHEN prm_date_expt THEN
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    WHEN get_output_type_expt THEN                       --*** �o�͋敪���̎擾�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_output_base
   * Description      : �o�͋��_�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_output_base(
      iv_base_code   IN VARCHAR2                                      -- 1.���_�R�[�h
    , ov_errbuf     OUT VARCHAR2                                      -- 2.�G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2                                      -- 3.���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2 )                                    -- 4.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_output_base'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    --�o�͑Ώۋ��_�R�[�h�擾
    --==============================================================
    IF ( iv_base_code IS NULL ) THEN
      -- ===============================
      -- ���O�C�����[�U�̏������_���擾
      -- ===============================
      xxcoi_common_pkg.get_belonging_base(
          in_user_id     => cn_created_by                             -- 1.���[�U�[ID
        , id_target_date => cd_creation_date                          -- 2.�Ώۓ�
        , ov_base_code   => gt_base_code                              -- 3.���_�R�[�h
        , ov_errbuf      => lv_errbuf                                 -- 4.�G���[�E���b�Z�[�W
        , ov_retcode     => lv_retcode                                -- 5.���^�[���E�R�[�h
        , ov_errmsg      => lv_errmsg                                 -- 6.���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_00010
                       , iv_token_name1  => cv_tok_api
                       , iv_token_value1 => cv_api_belogin
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    IF ( gt_base_code IS NULL ) THEN
      gt_base_code := iv_base_code;
    END IF;
--
    SELECT xbiv.base_code
          ,xbiv.base_short_name
    BULK COLLECT INTO gt_base_tab
    FROM   xxcoi_base_info_v xbiv
    WHERE  xbiv.focus_base_code = gt_base_code;
--
    gn_output_base_num := gt_base_tab.COUNT;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_output_base;
--
  /**********************************************************************************
   * Procedure Name   : ins_storage_info�i���[�v���j
   * Description      : �f�[�^�o�^(A-4)
   ***********************************************************************************/
  PROCEDURE ins_storage_info(
      ir_storage_rec  IN storage_info_cur%ROWTYPE                     -- 1.���ɏ��ꎞ�\���R�[�h�^
    , iv_zero_message IN VARCHAR2                                     -- 2.0�����b�Z�[�W
    , iv_output_type  IN VARCHAR2                                     -- 3.�p�����[�^���_�R�[�h
    , iv_base_code    IN VARCHAR2                                     -- 4.�p�����[�^���_��
    , iv_base_name    IN VARCHAR2                                     -- 5.�p�����[�^���_��
    , iv_date_from    IN VARCHAR2                                     -- 6.�p�����[�^���t(From)
    , iv_date_to      IN VARCHAR2                                     -- 7.�p�����[�^���t(To)
    , ov_errbuf      OUT VARCHAR2                                     -- 8.�G���[�E���b�Z�[�W                  --# �Œ� #
    , ov_retcode     OUT VARCHAR2                                     -- 9.���^�[���E�R�[�h                    --# �Œ� #
    , ov_errmsg      OUT VARCHAR2 )                                   -- 10.���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_storage_info';       -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    --==============================================================
    --���ɖ��m�F���X�g���[���[�N�e�[�u���ւ̃f�[�^�o�^
    --==============================================================
    INSERT INTO xxcoi_rep_storage_info (
        unconfirmed_storage_id
      , prm_output_kbn
      , prm_base_code
      , prm_base_name
      , prm_date_from
      , prm_date_to
      , base_code
      , base_name
      , slip_date
      , slip_num
      , warehouse_code
      , item_code
      , item_name
      , taste_term
      , factory_unique_mark
      , case_in_qty
      , ship_case_qty
      , ship_singly_qty
      , ship_qty
      , check_case_qty
      , check_singly_qty
      , check_qty
      , difference_summary_qty
      , slip_type
      , ship_base_code
      , ship_base_name
      , data_type
      , no_data_msg
      , last_update_date
      , last_updated_by
      , creation_date
      , created_by
      , last_update_login
      , request_id
      , program_application_id
      , program_id
      , program_update_date
    ) VALUES (
        xxcoi_rep_storage_info_s01.nextval
      , iv_output_type
      , iv_base_code
      , iv_base_name
      , iv_date_from
      , iv_date_to
      , storage_info_rec.base_code
      , storage_info_rec.base_name
      , storage_info_rec.slip_date
      , storage_info_rec.slip_num
      , storage_info_rec.check_warehouse_code
      , storage_info_rec.item_code
      , storage_info_rec.item_name
      , storage_info_rec.taste_term
      , storage_info_rec.factory_unique_mark
      , storage_info_rec.case_in_qty
      , storage_info_rec.ship_case_qty
      , storage_info_rec.ship_singly_qty
      , storage_info_rec.ship_summary_qty
      , storage_info_rec.check_case_qty
      , storage_info_rec.check_singly_qty
      , storage_info_rec.check_summary_qty
      , storage_info_rec.difference_summary_qty
      , storage_info_rec.slip_type
      , storage_info_rec.ship_base_code
      , storage_info_rec.ship_base_name
      , storage_info_rec.data_type
      , iv_zero_message
      , cd_last_update_date                                           -- �ŏI�X�V��
      , cn_last_updated_by                                            -- �ŏI�X�V��
      , cd_creation_date                                              -- �쐬��
      , cn_created_by                                                 -- �쐬��
      , cn_last_update_login                                          -- �ŏI�X�V���O�C��
      , cn_request_id                                                 -- �v��ID
      , cn_program_application_id                                     -- �A�v���P�[�V����ID
      , cn_program_id                                                 -- �v���O����ID
      , cd_program_update_date                                        -- �v���O�����X�V��
    );
--
    gn_normal_cnt := gn_normal_cnt + 1 ;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_storage_info;
--
  /**********************************************************************************
   * Procedure Name   : exec_svf_conc
   * Description      : SVF�R���J�����g�N��(A-5)
   ***********************************************************************************/
  PROCEDURE exec_svf_conc(
      ov_errbuf     OUT VARCHAR2                                      -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2                                      -- 2.���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2 )                                    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exec_svf_conc'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --SVF���[���ʊ֐�(SVF�R���J�����g�̋N��)
    --==============================================================
    xxccp_svfcommon_pkg.submit_svf_request(
       ov_retcode      => lv_retcode                                  -- ���^�[���R�[�h
      ,ov_errbuf       => lv_errbuf                                   -- �G���[���b�Z�[�W
      ,ov_errmsg       => lv_errmsg                                   -- ���[�U�[�E�G���[���b�Z�[�W
      ,iv_conc_name    => cv_pkg_name                                 -- �R���J�����g��
      ,iv_file_name    => cv_svf_id||TO_CHAR(SYSDATE,'YYYYMMDD')||cn_request_id     -- �o�̓t�@�C����
      ,iv_file_id      => cv_svf_id                                   -- ���[ID
      ,iv_output_mode  => cv_output_mode                              -- �o�͋敪
      ,iv_frm_file     => cv_frm_nm                                   -- �t�H�[���l���t�@�C����
      ,iv_vrq_file     => cv_vrq_nm                                   -- �N�G���[�l���t�@�C����
      ,iv_org_id       => fnd_global.org_id                           -- ORG_ID
      ,iv_user_name    => fnd_global.user_name                        -- ���O�C���E���[�U��
      ,iv_resp_name    => fnd_global.resp_name                        -- ���O�C���E���[�U�̐E�Ӗ�
      ,iv_doc_name     => cv_svf_id                                   -- ������
      ,iv_printer_name => NULL                                        -- �v�����^��
      ,iv_request_id   => cn_request_id                               -- �v��ID
      ,iv_nodata_msg   => gv_zero_message                             -- �f�[�^�Ȃ����b�Z�[�W
    );
--
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_00010
                     ,iv_token_name1  => cv_tok_api
                     ,iv_token_value1 => cv_api_svfcmn
                   );
      lv_errbuf := lv_errmsg;
      RAISE exec_svfapi_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN exec_svfapi_expt THEN                           --*** SVF���[���ʊ֐��G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END exec_svf_conc;
--
  /**********************************************************************************
   * Procedure Name   : get_table_lock
   * Description      : ���[�N�e�[�u�����b�N�擾(A-7)
   ***********************************************************************************/
  PROCEDURE get_table_lock(
      ov_errbuf     OUT VARCHAR2                                      -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2                                      -- 2.���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2 )                                    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_table_lock'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    CURSOR del_xrsi_tbl_cur
    IS
      SELECT 'X'
      FROM   xxcoi_rep_storage_info xrsi
      WHERE  xrsi.request_id = cn_request_id
      FOR UPDATE OF xrsi.request_id NOWAIT;
--
    -- *** ���[�J���E���R�[�h ***
    del_xrsi_tbl_rec  del_xrsi_tbl_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --���ɖ��m�F���X�g���[���[�N�e�[�u�����b�N�擾
    --==============================================================
    -- �J�[�\���I�[�v��
    OPEN del_xrsi_tbl_cur;
    FETCH del_xrsi_tbl_cur INTO del_xrsi_tbl_rec;
    CLOSE del_xrsi_tbl_cur;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN get_tbl_lock_expt THEN                          --*** ���[�N�e�[�u�����b�N�擾�G���[ ***
      IF ( del_xrsi_tbl_cur%ISOPEN ) THEN
        CLOSE del_xrsi_tbl_cur;
      END IF;
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_10156
                   );
      lv_errbuf := lv_errmsg;
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( del_xrsi_tbl_cur%ISOPEN ) THEN
        CLOSE del_xrsi_tbl_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( del_xrsi_tbl_cur%ISOPEN ) THEN
        CLOSE del_xrsi_tbl_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( del_xrsi_tbl_cur%ISOPEN ) THEN
        CLOSE del_xrsi_tbl_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_table_lock;
--
  /**********************************************************************************
   * Procedure Name   : del_storage_info
   * Description      : ���[�N�e�[�u���f�[�^�폜(A-8)
   ***********************************************************************************/
  PROCEDURE del_storage_info(
      ov_errbuf     OUT VARCHAR2                                      -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2                                      -- 2.���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2 )                                    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_storage_info'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
    --==============================================================
    --���ɖ��m�F���X�g���[���[�N�e�[�u���폜
    --==============================================================
    DELETE FROM xxcoi_rep_storage_info xrsi
    WHERE xrsi.request_id = cn_request_id
    ;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END del_storage_info;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      iv_base_code   IN VARCHAR2                                      -- 1.���_�R�[�h
    , iv_output_type IN VARCHAR2                                      -- 2.�o�͋敪
    , iv_date_from   IN VARCHAR2                                      -- 3.�o�͓��t�i���j
    , iv_date_to     IN VARCHAR2                                      -- 4.�o�͓��t�i���j
    , ov_errbuf     OUT VARCHAR2                                      -- 5.�G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2                                      -- 6.���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2 )                                    -- 7.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_belonging_base         VARCHAR2(4);                            -- �������_�R�[�h
    lv_prm_base_name          VARCHAR2(8);                            -- ���_��
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- A-1.��������
    -- ===============================
    init(
        iv_base_code   => iv_base_code                                -- 1.���_�R�[�h
      , iv_output_type => iv_output_type                              -- 2.�o�͋敪
      , iv_date_from   => SUBSTRB(iv_date_from,1,10)                  -- 3.�o�͓��t�i���j
      , iv_date_to     => SUBSTRB(iv_date_to,1,10)                    -- 4.�o�͓��t�i���j
      , ov_errbuf      => lv_errbuf                                   -- 5.�G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode     => lv_retcode                                  -- 6.���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg      => lv_errmsg                                   -- 7.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2.�o�͋��_�擾
    -- ===============================
    get_output_base(
        iv_base_code => iv_base_code                                  -- 1.���_�R�[�h
      , ov_errbuf    => lv_errbuf                                     -- 2.�G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode   => lv_retcode                                    -- 3.���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg    => lv_errmsg                                     -- 4.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �o�͋��_��1���ȏ゠��ꍇ
    IF ( gn_output_base_num > 0 ) THEN
--
      <<gn_base_cnt_loop>>
      FOR gn_output_base_cnt IN 1 .. gn_output_base_num LOOP
    -- ===============================
    -- A-3.�f�[�^�擾
    -- ===============================
        OPEN storage_info_cur( gt_base_tab(gn_output_base_cnt).base_code
                              , iv_output_type
                              , gv_date_from
                              , gv_date_to
                              );
        LOOP
          FETCH storage_info_cur INTO storage_info_rec;
          EXIT WHEN storage_info_cur%NOTFOUND;
--
          -- �Ώی����J�E���g
          gn_target_cnt :=  gn_target_cnt + 1;
--
    -- ===============================
    -- A-4.�f�[�^�o�^�i�f�[�^���j
    -- ===============================
          ins_storage_info(
              ir_storage_rec  => storage_info_rec                     -- 1.���ɏ��ꎞ�\���R�[�h�^
            , iv_zero_message => gv_zero_message                      -- 2.0�����b�Z�[�W
            , iv_output_type  => gt_output_type_meaning               -- 3.�o�͋敪
            , iv_base_code    => gt_base_tab(gn_output_base_cnt).base_code
                                                                      -- 4.���_�R�[�h
            , iv_base_name    => gt_base_tab(gn_output_base_cnt).base_name
                                                                      -- 5.���_��
            , iv_date_from    => SUBSTRB(iv_date_from,1,10)           -- 6.�o�͓��t�i���j
            , iv_date_to      => SUBSTRB(gv_date_to,1,10)             -- 7.�o�͓��t�i���j
            , ov_errbuf       => lv_errbuf                            -- 8.�G���[�E���b�Z�[�W           --# �Œ� #
            , ov_retcode      => lv_retcode                           -- 9.���^�[���E�R�[�h             --# �Œ� #
            , ov_errmsg       => lv_errmsg                            -- 10.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
        END LOOP;
        CLOSE storage_info_cur;
      END LOOP;
    END IF;
--
    IF (gn_target_cnt = 0) THEN
    -- ===============================
    -- A-6.0���o�̓��b�Z�[�W
    -- ===============================
      -- �o�͑Ώۃf�[�^0��
      gv_zero_message := xxccp_common_pkg.get_msg(
                            iv_application => cv_application
                          , iv_name        => cv_msg_00008
                         );
--
      lv_belonging_base := xxcoi_common_pkg.get_base_code(
          in_user_id     => cn_created_by
        , id_target_date => xxccp_common_pkg2.get_process_date
      );
      IF ( lv_belonging_base IS NULL ) THEN
        RAISE global_api_others_expt;
      END IF;
--
      SELECT SUBSTRB(hca.account_name,1,8)
      INTO   lv_prm_base_name
      FROM   hz_cust_accounts hca
      WHERE  hca.customer_class_code = '1'
      AND    hca.account_number = gt_base_code;
--
      ins_storage_info(
          ir_storage_rec  => storage_info_rec                         -- 1.���ɏ��ꎞ�\���R�[�h�^
        , iv_zero_message => gv_zero_message                          -- 2.0�����b�Z�[�W
        , iv_output_type  => gt_output_type_meaning                   -- 3.�o�͋敪
        , iv_base_code    => gt_base_code                             -- 4.���_�R�[�h
        , iv_base_name    => lv_prm_base_name                         -- 5.���_��
        , iv_date_from    => SUBSTRB(iv_date_from,1,10)               -- 6.�o�͓��t�i���j
        , iv_date_to      => SUBSTRB(gv_date_to,1,10)                 -- 7.�o�͓��t�i���j
        , ov_errbuf       => lv_errbuf                                -- 9.�G���[�E���b�Z�[�W           --# �Œ� #
        , ov_retcode      => lv_retcode                               -- 10.���^�[���E�R�[�h             --# �Œ� #
        , ov_errmsg       => lv_errmsg                                -- 11.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    END IF;
--
    COMMIT;
--
    -- ===============================
    -- A-5.SVF�R���J�����g�N��
    -- ===============================
    exec_svf_conc(
        ov_errbuf    => lv_errbuf                                     -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode   => lv_retcode                                    -- 2.���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg    => lv_errmsg                                     -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-7.���[�N�e�[�u�����b�N�擾
    -- ===============================
    get_table_lock(
        ov_errbuf    => lv_errbuf                                     -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode   => lv_retcode                                    -- 2.���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg    => lv_errmsg                                     -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-8.���[�N�e�[�u���f�[�^�폜
    -- ===============================
    del_storage_info(
        ov_errbuf    => lv_errbuf                                     -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode   => lv_retcode                                    -- 2.���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg    => lv_errmsg                                     -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      IF ( storage_info_cur%ISOPEN ) THEN
        CLOSE storage_info_cur;
      END IF;
      gn_error_cnt := gn_error_cnt + 1;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( storage_info_cur%ISOPEN ) THEN
        CLOSE storage_info_cur;
      END IF;
      gn_error_cnt := gn_error_cnt + 1;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( storage_info_cur%ISOPEN ) THEN
        CLOSE storage_info_cur;
      END IF;
      gn_error_cnt := gn_error_cnt + 1;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
      errbuf        OUT VARCHAR2                                      -- 1.�G���[�E���b�Z�[�W  --# �Œ� #
    , retcode       OUT VARCHAR2                                      -- 2.���^�[���E�R�[�h    --# �Œ� #
--    ��IN �����Ұ�������ꍇ�͓K�X�ҏW���ĉ������B
    , iv_base_code   IN  VARCHAR2                                     -- 3.���_�R�[�h
    , iv_output_type IN  VARCHAR2                                     -- 4.�o�͋敪
    , iv_date_from   IN  VARCHAR2                                     -- 5.���t�iFrom�j
    , iv_date_to     IN  VARCHAR2                                     -- 6.���t�iTo�j
  )
--
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
    --
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => 'LOG'
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
        iv_base_code   => iv_base_code                                -- 1.���_�R�[�h
      , iv_output_type => iv_output_type                              -- 2.�o�͋敪
      , iv_date_from   => iv_date_from                                -- 3.�o�͓��t�i���j
      , iv_date_to     => iv_date_to                                  -- 4.�o�͓��t�i���j
      , ov_errbuf      => lv_errbuf                                   -- 5.�G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode     => lv_retcode                                  -- 6.���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg      => lv_errmsg                                   -- 7.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      fnd_file.put_line(
         which => fnd_file.log
        ,buff  => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      fnd_file.put_line(
         which => fnd_file.log
        ,buff  => lv_errbuf --�G���[���b�Z�[�W
      );
-- add 2009/03/05 1.1 H.Wada #034 ��
      -- ���������̍Đݒ�
      gn_normal_cnt := 0;
-- add 2009/03/05 1.1 H.Wada #034 ��
    END IF;
    --��s�}��
    fnd_file.put_line(
       which => fnd_file.log
      ,buff  => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
       which => fnd_file.log
      ,buff  => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    fnd_file.put_line(
       which => fnd_file.log
      ,buff  => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    fnd_file.put_line(
       which => fnd_file.log
      ,buff  => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => lv_message_code
                   );
    fnd_file.put_line(
       which => fnd_file.log
      ,buff  => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCOI001A02R;
/
