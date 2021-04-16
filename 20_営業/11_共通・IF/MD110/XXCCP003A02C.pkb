CREATE OR REPLACE PACKAGE BODY APPS.XXCCP003A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCCP003A02C(body)
 * Description      : �≮���m��f�[�^�o��
 * MD.070           : �≮���m��f�[�^�o�� (MD070_IPO_CCP_003_A02)
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2016/03/23    1.0   H.Okada          [E_�{�ғ�_11084]�V�K�쐬
 *  2021/04/15    1.1   SCSK Y.Koh       [E_�{�ғ�_16026]
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
-- 2021/04/15 Ver1.1 ADD Start
  cv_xxcok_appl_name        CONSTANT VARCHAR2(10)  := 'XXCOK';
  cv_all_base_allowed       CONSTANT VARCHAR2(100) := 'XXCOK1_WHOLESALE_INVOICE_UPLOAD_ALL_BASE_ALLOWED';
  cv_err_msg_00003          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00003';   --�v���t�@�C���擾�G���[
  cv_err_msg_00030          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00030';   --��������擾�G���[
  cv_token_profile          CONSTANT VARCHAR2(10)  := 'PROFILE';         --�g�[�N����(PROFILE)
  cv_token_user_id          CONSTANT VARCHAR2(10)  := 'USER_ID';         --�g�[�N����(USER_ID)
-- 2021/04/15 Ver1.1 ADD End
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �x������
-- 2021/04/15 Ver1.1 ADD Start
  gv_all_base_allowed VARCHAR2(1);            --�J�X�^����v���t�@�C���擾�ϐ�
  gv_user_dept_code VARCHAR2(100);            --���[�U�S�����_
-- 2021/04/15 Ver1.1 ADD End
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
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100)   := 'XXCCP003A02C'; -- �p�b�P�[�W��
  cv_appl_short_name CONSTANT VARCHAR2(10)    := 'XXCCP';        -- �A�h�I���F���ʁEIF�̈�
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_payment_date_from  IN  VARCHAR2      --   1.�x���\���FROM
   ,iv_payment_date_to    IN  VARCHAR2      --   2.�x���\���TO
   ,ov_errbuf             OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode            OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg             OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'submain';           -- �v���O������
-- 2021/04/15 Ver1.1 ADD Start
    cv_flag_n               CONSTANT VARCHAR2(1)   := 'N';                 --N:�ΏۊO
-- 2021/04/15 Ver1.1 ADD End
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
-- 2021/04/15 Ver1.1 ADD Start
    lv_msg            VARCHAR2(5000) DEFAULT NULL;                --���b�Z�[�W�擾�ϐ�
    lb_retcode        BOOLEAN        DEFAULT TRUE;                --���b�Z�[�W�o�̖͂߂�l
    lv_profile_code   VARCHAR2(100)  DEFAULT NULL; --�v���t�@�C���l
    lv_user_dept_code VARCHAR2(100)  DEFAULT NULL; --���[�U�S�����_
-- 2021/04/15 Ver1.1 ADD End
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ld_process_date  DATE := xxccp_common_pkg2.get_process_date; -- �Ɩ����t
    lt_sales_ou_id   hr_operating_units.organization_id%TYPE;    -- �c�Ƒg�DID
--
-- 2021/04/15 Ver1.1 ADD Start
    -- =======================
    -- ���[�J����O
    -- =======================
    get_profile_expt        EXCEPTION;   -- �J�X�^����v���t�@�C���擾�G���[
    get_user_dept_code_expt EXCEPTION;   -- ��������擾�G���[
--
-- 2021/04/15 Ver1.1 ADD End
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �≮���m�背�R�[�h�擾
    CURSOR main_cur( iv_payment_date_from IN VARCHAR2
                   , iv_payment_date_to   IN VARCHAR2
                   )
    IS
      WITH
        base_v AS
          (SELECT hca.account_number AS base_code -- ���_�R�[�h
                 ,hp.party_name      AS base_name -- ���_��
           FROM   hz_cust_accounts hca -- �ڋq�}�X�^
                 ,hz_parties       hp  -- �p�[�e�B
           WHERE  hp.party_id =  hca.party_id
          )
       ,cust_v AS
          (SELECT hca.account_number AS cust_code -- �ڋq�R�[�h
                 ,hp.party_name      AS cust_name -- �ڋq��
           FROM   hz_cust_accounts hca -- �ڋq�}�X�^
                 ,hz_parties       hp  -- �p�[�e�B
           WHERE  hp.party_id =  hca.party_id
          )
       ,status_v AS
          (SELECT flvv.lookup_code   AS status      -- �X�e�[�^�X
                 ,flvv.meaning       AS status_name -- �X�e�[�^�X��
           FROM   fnd_lookup_values_vl flvv  -- �N�C�b�N�R�[�h
           WHERE  flvv.lookup_type   = 'XXCOK1_SALES_OUTLET_INV_STATUS'
             AND  flvv.enabled_flag  = 'Y'
             AND  ld_process_date   BETWEEN TRUNC( NVL( flvv.start_date_active ,ld_process_date ) )
                                        AND TRUNC( NVL( flvv.end_date_active   ,ld_process_date ) )
          )
       ,wholesale_v AS
          (SELECT xwbh.base_code                                    AS base_code
                 ,xwbh.supplier_code                                AS supplier_code
                 ,pvs.attribute1                                    AS supplier_name
                 ,TO_CHAR( xwbh.expect_payment_date, 'RRRR/MM/DD' ) AS expect_payment_date
-- 2021/04/15 Ver1.1 MOD Start
                 ,NVL( TO_CHAR( xwbl.selling_date, 'YYYY/MM/DD' ), TO_CHAR( TO_DATE(xwbl.selling_month,'YYYYMM'), 'YYYY/MM' ) )
                                                                    AS selling_date
--                 ,xwbl.selling_month                                AS selling_month
-- 2021/04/15 Ver1.1 MOD End
                 ,xwbh.cust_code                                    AS cust_code
-- 2021/04/15 Ver1.1 ADD Start
                 ,xwbl.bill_no                                      AS bill_no
                 ,xwbl.recon_slip_num                               AS recon_slip_num
-- 2021/04/15 Ver1.1 ADD End
                 ,SUM( xwbl.demand_amt )                            AS demand_amt
                 ,SUM( xwbl.payment_amt )                           AS payment_amt
                 ,xwbl.status                                       AS status
           FROM   xxcok_wholesale_bill_head  xwbh  -- �≮�������w�b�_
                 ,xxcok_wholesale_bill_line  xwbl  -- �≮����������
                 ,po_vendors                 pv    -- �d����}�X�^
                 ,po_vendor_sites_all        pvs   -- �d����T�C�g
           WHERE  xwbl.wholesale_bill_header_id   =  xwbh.wholesale_bill_header_id
-- 2021/04/15 Ver1.1 DEL Start
--             AND  xwbl.payment_amt                <> 0
-- 2021/04/15 Ver1.1 DEL End
             AND  pv.segment1                     =  xwbh.supplier_code
             AND  pvs.vendor_id                   =  pv.vendor_id
             AND  pvs.org_id                      =  lt_sales_ou_id  -- �c�Ƒg�DID
-- 2021/04/15 Ver1.1 DEL Start
--             AND  (     pvs.inactive_date         IS NULL
--                    OR  pvs.inactive_date         <  ld_process_date
--                  )
-- 2021/04/15 Ver1.1 DEL End
             AND  xwbh.expect_payment_date        >= TO_DATE( iv_payment_date_from ,'YYYY/MM/DD HH24:MI:SS' )
             AND  xwbh.expect_payment_date        <= TO_DATE( iv_payment_date_to   ,'YYYY/MM/DD HH24:MI:SS' )
           GROUP BY xwbh.base_code            -- ���_CD
                   ,xwbh.supplier_code        -- �d����CD
                   ,pvs.attribute1            -- �d���於
                   ,xwbh.expect_payment_date  -- �x���\���
                   ,xwbl.selling_month        -- ����N��
-- 2021/04/15 Ver1.1 ADD Start
                   ,xwbl.selling_date         -- ����Ώ۔N����
-- 2021/04/15 Ver1.1 ADD End
                   ,xwbh.cust_code            -- �ڋqCD
-- 2021/04/15 Ver1.1 ADD Start
                   ,xwbl.bill_no              -- ������No
                   ,xwbl.recon_slip_num       -- �x���`�[�ԍ�
-- 2021/04/15 Ver1.1 ADD End
                   ,xwbl.status               -- �X�e�[�^�X
          )
      SELECT wv.base_code            AS base_code
            ,bv.base_name            AS base_name
            ,wv.supplier_code        AS supplier_code
            ,wv.supplier_name        AS supplier_name
            ,wv.expect_payment_date  AS expect_payment_date
-- 2021/04/15 Ver1.1 MOD Start
            ,wv.selling_date         AS selling_date
--            ,wv.selling_month        AS selling_month
-- 2021/04/15 Ver1.1 MOD End
            ,wv.cust_code            AS cust_code
            ,cv.cust_name            AS cust_name
-- 2021/04/15 Ver1.1 ADD Start
            ,wv.bill_no              AS bill_no
            ,wv.recon_slip_num       AS recon_slip_num
-- 2021/04/15 Ver1.1 ADD End
            ,wv.demand_amt           AS demand_amt
            ,wv.payment_amt          AS payment_amt
-- 2021/04/15 Ver1.1 MOD Start
            ,RPAD(wv.status,2,' ')   AS status
--            ,wv.status               AS status
-- 2021/04/15 Ver1.1 MOD End
            ,sv.status_name          AS status_name
      FROM   wholesale_v    wv   -- �≮����VIEW
            ,base_v         bv   -- ���_VIEW
            ,cust_v         cv   -- �ڋqVIEW
            ,status_v       sv   -- �X�e�[�^�XVIEW
      WHERE  wv.base_code      = bv.base_code
        AND  wv.cust_code      = cv.cust_code
        AND  wv.status         = sv.status(+)
      ORDER BY wv.base_code            -- ���_CD
              ,wv.supplier_code        -- �d����CD
              ,wv.expect_payment_date  -- �x���\���
-- 2021/04/15 Ver1.1 MOD Start
              ,wv.selling_date         -- ����Ώ۔N����
--              ,wv.selling_month        -- ����N��
-- 2021/04/15 Ver1.1 MOD End
              ,wv.cust_code            -- �ڋqCD
-- 2021/04/15 Ver1.1 ADD Start
              ,wv.bill_no              -- ������No
              ,wv.recon_slip_num       -- �x���`�[�ԍ�
-- 2021/04/15 Ver1.1 ADD End
      ;
    -- ���C���J�[�\�����R�[�h�^
    main_rec  main_cur%ROWTYPE;
--
-- 2021/04/15 Ver1.1 ADD Start
    -- �x�����z�擾
    CURSOR deduction_recon_cur( iv_recon_slip_num IN VARCHAR2 )
    IS
      SELECT  ( SELECT NVL(SUM(xdrla.payment_amt),0) from XXCOK_DEDUCTION_RECON_LINE_AP xdrla where xdrla.recon_slip_num = iv_recon_slip_num )  +
              ( SELECT NVL(SUM(xdrlw.payment_amt),0) from XXCOK_DEDUCTION_RECON_LINE_WP xdrlw where xdrlw.recon_slip_num = iv_recon_slip_num )  +
              ( SELECT NVL(SUM(xapi.payment_amt ),0) from XXCOK_ACCOUNT_PAYMENT_INFO    xapi  where xapi .recon_slip_num = iv_recon_slip_num )
                                        AS  payment_amt ,   -- �x�����z
              xdrh.recon_status         AS  status      ,   -- �X�e�[�^�X
              flv.MEANING               AS  status_name     -- �X�e�[�^�X��
      FROM    fnd_lookup_values           flv , -- �N�C�b�N�R�[�h
              xxcok_deduction_recon_head  xdrh  -- �T�������w�b�_�[���
      WHERE   xdrh.recon_slip_num       = iv_recon_slip_num           AND
              flv.LOOKUP_TYPE           = 'XXCOK1_HEAD_ERASE_STATUS'  AND
              flv.LANGUAGE              = 'JA'                        AND
              flv.LOOKUP_CODE           = xdrh.recon_status;
--
    deduction_recon_rec deduction_recon_cur%ROWTYPE;
-- 2021/04/15 Ver1.1 ADD End
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    -- ===============================
    -- init��
    -- ===============================
    BEGIN
      SELECT hou.organization_id AS sales_ou_id
      INTO   lt_sales_ou_id
      FROM   hr_operating_units hou
      WHERE  hou.name = 'SALES-OU'
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := '�c�Ƒg�DID�̎擾�Ɏ��s���܂����B';
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
-- 2021/04/15 Ver1.1 ADD Start
    --==============================================================
    -- �J�X�^���E�v���t�@�C���E�I�v�V�����擾
    --==============================================================
    BEGIN  --lv_all_base_allow_flag
      gv_all_base_allowed := FND_PROFILE.VALUE( cv_all_base_allowed );
    IF ( gv_all_base_allowed IS NULL ) THEN
      lv_profile_code := cv_all_base_allowed;
      RAISE get_profile_expt;
    END IF;
    END;
--
    -- =============================================================================
    -- 3.���[�U�̏���������擾
    -- =============================================================================
    BEGIN
      lv_user_dept_code := xxcok_common_pkg.get_department_code_f(
                             in_user_id => cn_created_by
                           );
--
      IF ( lv_user_dept_code IS NULL ) THEN
        RAISE get_user_dept_code_expt;
    END IF;
    gv_user_dept_code := lv_user_dept_code ;
    END;
--
-- 2021/04/15 Ver1.1 ADD End
    --==============================================================
    -- ���̓p�����[�^�o��
    --==============================================================
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => '�x���\���FROM : ' ||
                                TO_CHAR( TO_DATE( iv_payment_date_from ,'YYYY/MM/DD HH24:MI:SS' ) ,'YYYY/MM/DD' )
                     );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => '�x���\���TO   : ' ||
                                TO_CHAR( TO_DATE( iv_payment_date_to   ,'YYYY/MM/DD HH24:MI:SS' ) ,'YYYY/MM/DD' )
                     );
--
    --==============================================================
    -- ���̓p�����[�^�`�F�b�N
    --==============================================================
    -- �x���\���FROM > �x���\���TO �̏ꍇ
    IF ( TO_DATE( iv_payment_date_from, 'YYYY/MM/DD HH24:MI:SS' ) > TO_DATE( iv_payment_date_to, 'YYYY/MM/DD HH24:MI:SS' ) ) THEN
      ov_errbuf  := '�x���\���FROM �� �x���\���TO �ȑO�̓��t���w�肵�ĉ������B';
      ov_retcode := cv_status_error;
    ELSE
      -- ===============================
      -- ������
      -- ===============================
--
      -- ���ږ��o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
-- 2021/04/15 Ver1.1 MOD Start
        ,buff   =>           '"' || '�폜�敪'                   || '"' -- �폜�敪
                   || ',' || '"' || '���_CD'                     || '"' -- ���_CD
--        ,buff   =>           '"' || '���_CD'                     || '"' -- ���_CD
-- 2021/04/15 Ver1.1 MOD End
                   || ',' || '"' || '���_��'                     || '"' -- ���_��
                   || ',' || '"' || '�d����CD'                   || '"' -- �d����CD
                   || ',' || '"' || '�d���於'                   || '"' -- �d���於
                   || ',' || '"' || '�x���\���'                 || '"' -- �x���\���
-- 2021/04/15 Ver1.1 MOD Start
                   || ',' || '"' || '����Ώ۔N����'             || '"' -- ����Ώ۔N����
--                   || ',' || '"' || '����Ώ۔N��'               || '"' -- ����Ώ۔N��
-- 2021/04/15 Ver1.1 MOD End
                   || ',' || '"' || '�ڋqCD'                     || '"' -- �ڋqCD
                   || ',' || '"' || '�ڋq��'                     || '"' -- �ڋq��
-- 2021/04/15 Ver1.1 ADD Start
                   || ',' || '"' || '������No'                   || '"' -- ������No
                   || ',' || '"' || '�x���`�[�ԍ�'               || '"' -- �x���`�[�ԍ�
-- 2021/04/15 Ver1.1 ADD End
                   || ',' || '"' || '�������z'                   || '"' -- �������z
                   || ',' || '"' || '�x�����z'                   || '"' -- �x�����z
                   || ',' || '"' || '�X�e�[�^�X'                 || '"' -- �X�e�[�^�X
                   || ',' || '"' || '�X�e�[�^�X��'               || '"' -- �X�e�[�^�X��
      );
      -- �f�[�^���o��(CSV)
      FOR main_rec IN main_cur( iv_payment_date_from, iv_payment_date_to ) LOOP
-- 2021/04/15 Ver1.1 ADD Start
        IF ( gv_all_base_allowed  <> cv_flag_n )
          OR ( gv_all_base_allowed = cv_flag_n AND lv_user_dept_code = main_rec.base_code )
          THEN
-- 2021/04/15 Ver1.1 ADD End
        --�����Z�b�g
          gn_target_cnt := gn_target_cnt + 1;
--
-- 2021/04/15 Ver1.1 ADD Start
          IF  main_rec.recon_slip_num IS  NOT NULL  THEN
            OPEN  deduction_recon_cur(main_rec.recon_slip_num);
            FETCH deduction_recon_cur INTO  deduction_recon_rec;
            CLOSE deduction_recon_cur;
            main_rec.payment_amt  :=  deduction_recon_rec.payment_amt ;
            main_rec.status       :=  deduction_recon_rec.status      ;
            main_rec.status_name  :=  deduction_recon_rec.status_name ;
          END IF;
-- 2021/04/15 Ver1.1 ADD End
--
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
-- 2021/04/15 Ver1.1 MOD Start
            ,buff   =>         '"' || NULL                         || '"' -- �폜�敪
                     || ',' || '"' || main_rec.base_code           || '"' -- ���_CD
--            ,buff   =>         '"' || main_rec.base_code           || '"' -- ���_CD
-- 2021/04/15 Ver1.1 MOD End
                     || ',' || '"' || main_rec.base_name           || '"' -- ���_��
                     || ',' || '"' || main_rec.supplier_code       || '"' -- �d����CD
                     || ',' || '"' || main_rec.supplier_name       || '"' -- �d���於
                     || ',' || '"' || main_rec.expect_payment_date || '"' -- �x���\���
-- 2021/04/15 Ver1.1 MOD Start
                     || ',' || '"' || main_rec.selling_date        || '"' -- ����Ώ۔N����
--                     || ',' || '"' || main_rec.selling_month       || '"' -- ����Ώ۔N��
-- 2021/04/15 Ver1.1 MOD End
                     || ',' || '"' || main_rec.cust_code           || '"' -- �ڋqCD
                     || ',' || '"' || main_rec.cust_name           || '"' -- �ڋq��
-- 2021/04/15 Ver1.1 ADD Start
                     || ',' || '"' || main_rec.bill_no             || '"' -- ������No
                     || ',' || '"' || main_rec.recon_slip_num      || '"' -- �x���`�[�ԍ�
-- 2021/04/15 Ver1.1 ADD End
                     || ',' || '"' || main_rec.demand_amt          || '"' -- �������z
                     || ',' || '"' || main_rec.payment_amt         || '"' -- �x�����z
                     || ',' || '"' || main_rec.status              || '"' -- �X�e�[�^�X
                     || ',' || '"' || main_rec.status_name         || '"' -- �X�e�[�^�X��
          );
-- 2021/04/15 Ver1.1 ADD Start
        END IF ;
-- 2021/04/15 Ver1.1 ADD End
      END LOOP;
--
      -- ��������=�Ώی���
      gn_normal_cnt  := gn_target_cnt;
      -- �Ώی���=0�ł���΃��b�Z�[�W�o��
      IF ( gn_target_cnt = 0 ) THEN
       FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => CHR(10) || '�Ώۃf�[�^�͂���܂���B'
       );
      END IF;
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
--
--#################################  �Œ��O������ START   ###################################
--
-- 2021/04/15 Ver1.1 ADD Start
    -- *** �v���t�@�C���擾�G���[ ***
    WHEN get_profile_expt THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_00003
                , iv_token_name1  => cv_token_profile
                , iv_token_value1 => lv_profile_code
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    WHEN get_user_dept_code_expt THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_00030
                , iv_token_name1  => cv_token_user_id
                , iv_token_value1 => cn_created_by
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;-- 2021/04/15 Ver1.1 ADD End
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
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
    errbuf                OUT VARCHAR2      --   �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode               OUT VARCHAR2      --   ���^�[���E�R�[�h    --# �Œ� #
   ,iv_payment_date_from  IN  VARCHAR2      --   1.�x���\���FROM
   ,iv_payment_date_to    IN  VARCHAR2      --   2.�x���\���TO
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00001'; -- �x���������b�Z�[�W
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
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
       iv_payment_date_from  --   1.�x���\���FROM
      ,iv_payment_date_to    --   2.�x���\���TO
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCCP003A02C;
/
