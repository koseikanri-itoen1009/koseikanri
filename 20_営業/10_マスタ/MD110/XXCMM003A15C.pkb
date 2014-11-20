CREATE OR REPLACE PACKAGE BODY xxcmm003a15c
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM003A15C(body)
 * Description      : HHT���Ɍڋq�ւ̍ŏI�������A�g���邽�߁A�ڋq�}�X�^��ɍŏI�������
 *                    �ێ�����K�v������܂��B
 *                    ���@�\������ŉғ������A�ŐV�̍ŏI������������X�V���܂��B
 *                    �ڋq�̒��~���s�����f�Ƃ��āA�ŏI��������Q�Ƃ��Ĉ����Ԏ����
 *                    �������Ă��Ȃ��ڋq�𔻒f���܂��B
 *                    �i������q�`�F�b�N���X�g�ɏo�͂���܂��B�j
 * MD.050           : �ŏI������X�V MD050_CMM_003_A15
 * Version          : Draft3A
 *
 * Program List
 * -------------------- -----------------------------------------------------------------
 *  Name                 Description
 * -------------------- -----------------------------------------------------------------
 *  prc_upd_hz_parties              �ڋq�X�e�[�^�X�X�V(A-6)
 *  prc_ins_xxcmm_cust_accounts     �ڋq�ǉ����e�[�u���o�^(A-5)
 *  prc_upd_xxcmm_cust_accounts     �ڋq�ǉ����e�[�u���ŏI������X�V(A-4)
 *  prc_init                        ��������(A-1)
 *  submain                         ���C�������v���V�[�W��(A-2:�����Ώۃf�[�^���o)
 *                                    �Eprc_init
 *                                    �Eprc_upd_xxcmm_cust_accounts
 *                                    �Eprc_upd_hz_parties
 *  main                            �R���J�����g���s�t�@�C���o�^�v���V�[�W��(A-7:�I������)
 *                                    �Esubmain
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/02/03    1.0   SCS Okuyama      �V�K�쐬
 *  2009/02/27    1.1   Yutaka.Kuboshima �ڋq�X�e�[�^�X�X�V������ύX
 *  2009/05/27    1.2   Yutaka.Kuboshima ��QT1_0816,T1_0863�̑Ή�
 *  2009/08/31    1.3   Yutaka.Kuboshima ��Q0001229�̑Ή�
 *  2009/12/18    1.4   Yutaka.Kuboshima ��QE_�{�ғ�_00540�̑Ή�
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  cv_msg_bracket_f          CONSTANT VARCHAR2(1) := '[';
  cv_msg_bracket_t          CONSTANT VARCHAR2(1) := ']';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg              VARCHAR2(2000);
  gv_sep_msg              VARCHAR2(2000);
  gv_exec_user            VARCHAR2(100);
  gv_conc_name            VARCHAR2(30);
  gv_conc_status          VARCHAR2(30);
  gn_target_cnt           NUMBER;       -- �Ώی���
  gn_normal_cnt           NUMBER;       -- ���팏��
  gn_error_cnt            NUMBER;       -- �G���[����
  gn_warn_cnt             NUMBER;       -- �X�L�b�v����
  gn_xx_cust_acnt_upd_cnt NUMBER;       -- �ڋq�ǉ����e�[�u���X�V����
  gn_hz_pts_upd_cnt       NUMBER;       -- �p�[�e�B�e�[�u���X�V����
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt        EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt            EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt     EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  global_check_para_expt     EXCEPTION;     -- �p�����[�^�G���[
  global_check_lock_expt     EXCEPTION;     -- ���b�N�擾�G���[
  global_get_base_cd_expt    EXCEPTION;     -- ���㋒�_�擾�G���[
  --
  PRAGMA EXCEPTION_INIT(global_check_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_apl_name_ccp           CONSTANT VARCHAR2(5)  := 'XXCCP';                       -- �A�h�I���F���ʁEIF�̈�
  cv_apl_name_cmm           CONSTANT VARCHAR2(5)  := 'XXCMM';                       -- �A�h�I���F�}�X�^�E�}�X�^�̈�
  cv_pkg_name               CONSTANT VARCHAR2(12) := 'XXCMM003A15C';                -- �p�b�P�[�W��
  -- ���b�Z�[�W�R�[�h
  cv_msg_xxccp_91003        CONSTANT VARCHAR2(16) := 'APP-XXCCP1-91003';            -- ���Ѵװ
  cv_msg_xxcmm_00001        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00001';            -- �Ώۃf�[�^����
  cv_msg_xxcmm_00002        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00002';            -- �v���t�@�C���擾�G���[
  cv_msg_xxcmm_00008        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00008';            -- ���b�N�G���[
  cv_msg_xxcmm_00305        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00305';            -- �p�����[�^�G���[
  cv_msg_xxcmm_00311        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00311';            -- �ŏI������X�V�G���[
  cv_msg_xxcmm_00309        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00309';            -- �ڋq�X�e�[�^�X�X�V�G���[
  cv_msg_xxcmm_00331        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00331';            -- ��v�N���[�Y�X�e�[�^�X�擾�G���[
  cv_msg_xxcmm_00033        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00033';            -- �X�V�������b�Z�[�W
  -- ���b�Z�[�W�g�[�N��
  cv_tkn_ng_profile         CONSTANT VARCHAR2(10) := 'NG_PROFILE';                  -- �v���t�@�C����
  cv_tkn_ng_table           CONSTANT VARCHAR2(8)  := 'NG_TABLE';                    -- �e�[�u����
  cv_tkn_cust_code          CONSTANT VARCHAR2(7)  := 'CUST_CD';                     -- �ڋq�R�[�h
  cv_tkn_fnl_trn_date       CONSTANT VARCHAR2(12) := 'FINAL_TRN_DT';                -- �ŏI�����
  cv_tkn_table              CONSTANT VARCHAR2(8)  := 'TBL_NAME';                    -- �e�[�u����
  --
  cv_tbl_nm_xcac            CONSTANT VARCHAR2(12) := '�ڋq�ǉ����';                -- XXCMM_CUST_ACCOUNTS
  cv_tbl_nm_hzpt            CONSTANT VARCHAR2(8)  := '�p�[�e�B';                    -- HZ_PARTIES
  cv_date_fmt               CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';                  -- ���t�t�H�[�}�b�g
  cv_month_fmt              CONSTANT VARCHAR2(6)  := 'YYYYMM';                      -- ���t�H�[�}�b�g
  cv_date_time_fmt          CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS';       -- �����t�H�[�}�b�g
  cv_time_max               CONSTANT VARCHAR2(9)  := ' 23:59:59';
  cv_profile_ctrl_cal       CONSTANT VARCHAR2(26) := 'XXCMM1_003A00_SYS_CAL_CODE';  -- ���щғ�������޺��ޒ�`���̧��
  cv_profile_gl_cal         CONSTANT VARCHAR2(26) := 'XXCMM1_003A00_GL_PERIOD_MN';  -- ��v�J�����_����`���̧��
  cv_profile_ar_bks         CONSTANT VARCHAR2(25) := 'XXCMM1_003A15_AR_BOOKS_NM';   -- �c�ƒ����`�����̧��
  cv_lang_ja                CONSTANT VARCHAR2(2)  := 'JA';                          -- ����i���{�j
  cv_flag_yes               CONSTANT VARCHAR2(1)  := 'Y';                           -- �t���O�iYes�j
  cv_flag_no                CONSTANT VARCHAR2(1)  := 'N';                           -- �t���O�iNo�j
  cv_lkup_type_gyotai_sho   CONSTANT VARCHAR2(21) := 'XXCMM_CUST_GYOTAI_SHO';       -- �Q�ƃ^�C�v�i�Ƒԏ����ށj
  cv_lkup_type_gyotai_chu   CONSTANT VARCHAR2(21) := 'XXCMM_CUST_GYOTAI_CHU';       -- �Q�ƃ^�C�v�i�ƑԒ����ށj
  cv_sal_cls_usually        CONSTANT VARCHAR2(1)  := '1';                           -- ����敪�i�ʏ�j
  cv_sal_cls_bargain        CONSTANT VARCHAR2(1)  := '2';                           -- ����敪�i�����j
  cv_sal_cls_vdsale         CONSTANT VARCHAR2(1)  := '3';                           -- ����敪�i�x���_����j
  cv_sal_cls_consume        CONSTANT VARCHAR2(1)  := '4';                           -- ����敪�i�����EVD�����j
  cv_sal_cls_cvrsale        CONSTANT VARCHAR2(1)  := '9';                           -- ����敪�i��U���i�̔̔��j
  cv_deli_slp_deliver       CONSTANT VARCHAR2(1)  := '1';                           -- �[�i�`�[�敪�i�[�i�j
  cv_deli_slp_returned      CONSTANT VARCHAR2(1)  := '2';                           -- �[�i�`�[�敪�i�ԕi�j
  cv_deli_slp_crtn_deli     CONSTANT VARCHAR2(1)  := '3';                           -- �[�i�`�[�敪�i�[�i�����j
  cv_sgl_space              CONSTANT VARCHAR2(1)  := CHR(32);                       -- ���p�X�y�[�X����
  cv_cust_status_admit      CONSTANT VARCHAR2(2)  := '30';                          -- �ڋq�X�e�[�^�X�i���F�ρj
  cv_cust_status_cust       CONSTANT VARCHAR2(2)  := '40';                          -- �ڋq�X�e�[�^�X�i�ڋq�j
  cv_apl_short_nm_ar        CONSTANT VARCHAR2(2)  := 'AR';                          -- ���ع���ݒZ�k���iAR�j
  cv_cal_status_close       CONSTANT VARCHAR2(1)  := 'C';                           -- �J�����_�X�e�[�^�X�i�N���[�Y�j
  cv_gyotai_chu_vd          CONSTANT VARCHAR2(2)  := '11';                          -- �ƑԒ����ށiVD�j
  cd_min_date               CONSTANT DATE         := TO_DATE('1900/01/01', cv_date_fmt);  -- �ŏ����t
  cv_sel_trn_type_exchg     CONSTANT VARCHAR2(1)  := '0';                           -- ���ѐU�֋敪�i�U�֊����j
  cv_rpt_dec_flg_rpt        CONSTANT VARCHAR2(1)  := '0';                           -- ����m��t���O�i����j
  cv_rpt_dec_flg_dec        CONSTANT VARCHAR2(1)  := '1';                           -- ����m��t���O�i�m��j
  cv_crt_flg_correction     CONSTANT VARCHAR2(1)  := '1';                           -- �U�߃t���O�i�U��߂����j
  cv_crt_flg_others         CONSTANT VARCHAR2(1)  := '0';                           -- �U�߃t���O�i�U��߂����ȊO�j
-- 2009/05/27 Ver1.2 ��QT1_0863 add start by Yutaka.Kuboshima
  cv_gyotai_sho_vd24        CONSTANT VARCHAR2(2)  := '24';                          -- �Ƒԏ����ށi�t���T�[�r�X�i�����j�u�c�j
  cv_gyotai_sho_vd25        CONSTANT VARCHAR2(2)  := '25';                          -- �Ƒԏ����ށi�t���T�[�r�X�u�c�j
-- 2009/05/27 Ver1.2 ��QT1_0863 add end by Yutaka.Kuboshima
  --
  cv_para01_name            CONSTANT VARCHAR2(12) := '������(FROM)';                -- �ݶ��ĥ���Ұ���01
  cv_para02_name            CONSTANT VARCHAR2(12) := '������(TO)  ';                -- �ݶ��ĥ���Ұ���02
  cv_para_at_name           CONSTANT VARCHAR2(10) := '�����擾�l';                  -- �ݶ��ĥ���Ұ���_����
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_cal_code           VARCHAR2(30);   -- �V�X�e���ғ����J�����_�R�[�h�l
  gv_gl_cal_code        VARCHAR2(30);   -- ��v�J�����_�R�[�h�l
  gd_now_proc_date      DATE;           -- �Ɩ����t
  gd_para_proc_date_f   DATE;           -- ������(From)
  gd_para_proc_date_t   DATE;           -- ������(To)
  gd_last_month_day     DATE;           -- �O������
  gv_prev_month_cls_status  gl_period_statuses.closing_status%TYPE; -- ��v�J�����_�E�O���N���[�Y�X�e�[�^�X
  --
--
  -- ===============================
  -- ���[�U�[��`�J�[�\��
  -- ===============================
  --
  -- A-2.�����Ώۃf�[�^���o�J�[�\��
  --
  CURSOR  XXCMM003A15C_cur
  IS
    SELECT
-- 2009/08/31 Ver1.3 add start by Yutaka.Kuboshima
--    �q���g��̒ǉ�
      /*+ FIRST_ROWS LEADING(fidt) USE_NL(hzca,hzpt,xcac)*/
-- 2009/08/31 Ver1.3 add end by Yutaka.Kuboshima
      hzca.cust_account_id        AS  cust_id,                -- �ڋqID
      hzca.party_id               AS  party_id,               -- �p�[�e�BID
      fidt.cust_code              AS  cust_code,              -- �ڋq�R�[�h
      hzpt.duns_number_c          AS  cust_status,            -- �ڋq�X�e�[�^�X
      fidt.new_tran_date          AS  new_tran_date,          -- �ŐV�����
-- 2009/05/27 Ver1.2 ��QT1_0816,T1_0863 modify start by Yutaka.Kuboshima
--      fidt.past_deli_date         AS  past_deli_date,         -- �O���ŐV�����
      xcac.final_tran_date        AS  final_tran_date,        -- �ŏI�����
-- 2009/05/27 Ver1.2 ��QT1_0816,T1_0863 modify end by Yutaka.Kuboshima
      xcac.past_final_tran_date   AS  past_final_tran_date,   -- �O���ŏI�����
      fidt.past_deli_date         AS  past_new_fnl_trn_dt,    -- �O���ŐV�����
-- 2009/05/27 Ver1.2 delete start by Yutaka.Kuboshima
--      xcac.final_call_date        AS  final_call_date,        -- �ŏI�K���
-- 2009/05/27 Ver1.2 delete end by Yutaka.Kuboshima
      xcac.cnvs_date              AS  cnvs_date,              -- �ڋq�l����
      xcac.start_tran_date        AS  start_tran_date,        -- ��������
-- 2009/05/27 Ver1.2 delete start by Yutaka.Kuboshima
--      gyti.business_mid_type      AS  business_mid_type,      -- �ƑԒ�����
-- 2009/05/27 Ver1.2 delete end by Yutaka.Kuboshima
      hzpt.ROWID                  AS  hzpt_rowid,             -- ���R�[�hID�i�p�[�e�B�j
      xcac.ROWID                  AS  xcac_rowid,             -- ���R�[�hID�i�ڋq�ǉ����j
-- 2009/05/27 Ver.12 ��QT1_0816,T1_0863 add start by Yutaka.Kuboshima
      fidt.old_tran_date          AS  old_tran_date,          -- �őO�����
      xcac.business_low_type      AS  business_low_type       -- �Ƒԏ�����
-- 2009/05/27 Ver.12 ��QT1_0816,T1_0863 add end by Yutaka.Kuboshima
    FROM
      (
        SELECT
          xfid.cust_code              AS  cust_code,
          MAX(xfid.new_tran_date)     AS  new_tran_date,
-- 2009/05/27 Ver1.3 ��QT1_0863 add start by Yutaka.Kuboshima
          MIN(xfid.new_tran_date)     AS  old_tran_date,
-- 2009/05/27 Ver1.3 ��QT1_0863 add end by Yutaka.Kuboshima
          MAX(xfid.past_deli_date)    AS  past_deli_date
        FROM
          (
            -- �̔����я��
            SELECT
              xseh.ship_to_customer_code    AS  cust_code,        -- �ڋq�R�[�h�y�[�i��z
              xseh.delivery_date            AS  new_tran_date,    -- �[�i���i�ŐV������j
              CASE WHEN (TRUNC(xseh.delivery_date) <= gd_last_month_day) THEN
                xseh.delivery_date
              ELSE
                NULL
              END                           AS  past_deli_date    -- �O���ŐV�����
            FROM
              xxcos_sales_exp_headers       xseh    -- �̔����уw�b�_
            WHERE
                  EXISTS(
                    SELECT
                      'X'
                    FROM
                          xxcos_sales_exp_lines   xsel  -- �̔����і���
                    WHERE
                          xsel.sales_exp_header_id = xseh.sales_exp_header_id
                      AND xsel.sales_class IN (
                            cv_sal_cls_usually, cv_sal_cls_bargain, cv_sal_cls_vdsale,
                            cv_sal_cls_consume,  cv_sal_cls_cvrsale
                          )   -- ����敪
                  )
              AND xseh.business_date BETWEEN gd_para_proc_date_f AND gd_para_proc_date_t
              AND xseh.dlv_invoice_class IN (
                    cv_deli_slp_deliver, cv_deli_slp_returned, cv_deli_slp_crtn_deli
                  )   -- �[�i�`�[�敪
            UNION ALL
            -- ���ѐU�֏��
            SELECT
              xsti.cust_code                AS  cust_code,      -- �ڋq�R�[�h
              xsti.selling_date             AS  new_tran_date,  -- �v����i�ŐV������j
              CASE WHEN (TRUNC(xsti.selling_date) <= gd_last_month_day) THEN
                xsti.selling_date
              ELSE
                NULL
              END                           AS  past_deli_date    -- �O���ŐV�����
            FROM
              xxcok_selling_trns_info       xsti                  -- ������ѐU�֏��
            WHERE
-- 2009/08/31 Ver1.3 delete start by Yutaka.Kuboshima
--                  EXISTS(
--                    SELECT
--                      'X'
--                    FROM
--                      xxcok_selling_to_info     xsto              -- ����U�֐���
--                    WHERE
--                          xsto.start_month            <=  TO_CHAR(xsti.registration_date, cv_month_fmt)
--                      AND xsto.selling_to_cust_code   =   xsti.cust_code
--                  )
-- 2009/08/31 Ver1.3 delete end by Yutaka.Kuboshima
                 xsti.registration_date  BETWEEN gd_para_proc_date_f AND gd_para_proc_date_t
          )   xfid
        GROUP BY
          xfid.cust_code
      )                     fidt,   -- �̔����с����ѐU��
      hz_cust_accounts      hzca,   -- �ڋq�}�X�^
      hz_parties            hzpt,   -- �p�[�e�B
      xxcmm_cust_accounts   xcac    -- �ڋq�ǉ����
-- 2009/05/27 Ver1.2 ��QT1_0863 delete start by Yutaka.Kuboshima
--      (
--        SELECT
--          lkch.lookup_code      AS  business_mid_type,  -- �ƑԒ����ދ敪
--          lkch.meaning          AS  business_mid_name,  -- �ƑԒ����ދ敪��
--          lksh.lookup_code      AS  business_low_type,  -- �Ƒԏ����ދ敪
--          lksh.meaning          AS  business_low_name   -- �Ƒԏ����ދ敪��
--        FROM
--          fnd_lookup_values     lkch,   -- LOOKUP(�ƑԒ�����)
--          fnd_lookup_values     lksh    -- LOOKUP(�Ƒԏ�����)
--        WHERE
--              lksh.attribute1     =   lkch.lookup_code
--          AND lksh.lookup_type    =   cv_lkup_type_gyotai_sho
--          AND lksh.enabled_flag   =   cv_flag_yes
--          AND lksh.language       =   cv_lang_ja
--          AND lkch.lookup_type    =   cv_lkup_type_gyotai_chu
--          AND lkch.enabled_flag   =   cv_flag_yes
--          AND lkch.language       =   cv_lang_ja
--      )                     gyti    -- �Ƒԕ���
-- 2009/05/27 Ver1.2 ��QT1_0863 delete end by Yutaka.Kuboshima
    WHERE
          fidt.cust_code              = hzca.account_number
      AND hzca.cust_account_id        = xcac.customer_id
      AND hzca.party_id               = hzpt.party_id
-- 2009/05/27 Ver1.2 ��QT1_0863 delete start by Yutaka.Kuboshima
--      AND xcac.business_low_type      = gyti.business_low_type(+)
-- 2009/05/27 Ver1.2 ��QT1_0863 delete end by Yutaka.Kuboshima
    FOR UPDATE OF xcac.customer_id, hzpt.party_id NOWAIT
  ;
--
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_upd_xxcmm_cust_accounts
   * Description      : �ڋq�X�e�[�^�X�X�V(A-5)
   ***********************************************************************************/
  PROCEDURE prc_upd_hz_parties(
    iv_rec        IN  XXCMM003A15C_cur%ROWTYPE,   -- �����Ώۃf�[�^���R�[�h
    ov_errbuf     OUT VARCHAR2,                   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,                   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_upd_hz_parties'; -- �v���O������
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
    lv_step       VARCHAR2(10);     -- �X�e�b�v
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
    lv_step := 'A-5.1';
    --
    -- �ڋq�X�e�[�^�X�X�VSQL��
-- 2009/02/27 delete start
--    UPDATE
--      hz_parties                    hzpt                          -- �p�[�e�B
--    SET
--      hzpt.duns_number_c            = cv_cust_status_cust,        -- �ڋq�X�e�[�^�X�i�ڋq�j
--      hzpt.last_updated_by          = cn_last_updated_by,         -- �ŏI�X�V��
--      hzpt.last_update_date         = cd_last_update_date,        -- �ŏI�X�V��
--      hzpt.last_update_login        = cn_last_update_login,       -- �ŏI�X�V���O�C��
--      hzpt.request_id               = cn_request_id,              -- �v��ID
--      hzpt.program_application_id   = cn_program_application_id,  -- �ݶ��ĥ��۸��ѥ���ع����ID
--      hzpt.program_id               = cn_program_id,              -- �ݶ��ĥ��۸���ID
--      hzpt.program_update_date      = cd_program_update_date      -- �v���O�����X�V��
--    WHERE
--          hzpt.rowid                = iv_rec.hzpt_rowid           -- ���R�[�hID�i�p�[�e�B�j
--    ;
-- 2009/02/27 delete end
-- 2009/02/27 add start
    -- ���ʊ֐��p�[�e�B�}�X�^�X�V�p�֐��ďo��
    xxcmm_003common_pkg.update_hz_party(iv_rec.party_id,
                                        cv_cust_status_cust,
                                        lv_errbuf,
                                        lv_retcode,
                                        lv_errmsg);
    -- �������ʂ��G���[�̏ꍇ��RAISE
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
-- 2009/02/27 add end
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
-- 2009/02/27 add start
    WHEN global_process_expt THEN
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_cmm,            -- �A�v���P�[�V�����Z�k��
                        iv_name         =>  cv_msg_xxcmm_00309,         -- ���b�Z�[�W�R�[�h
                        iv_token_name1  =>  cv_tkn_cust_code,           -- �g�[�N���R�[�h1
                        iv_token_value1 =>  iv_rec.cust_code            -- �g�[�N���l1
                      );
      ov_errmsg   :=  lv_errmsg;
      lv_errbuf   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_ccp,          -- �A�v���P�[�V�����Z�k��
                        iv_name         =>  cv_msg_xxccp_91003        -- ���b�Z�[�W�R�[�h
                      );
      ov_errbuf   := lv_errbuf || cv_msg_bracket_f || 
                     cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || cv_msg_bracket_t;
      -- �����X�e�[�^�X�Z�b�g
      ov_retcode  :=  cv_status_error;
-- 2009/02/27 add end
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_cmm,            -- �A�v���P�[�V�����Z�k��
                        iv_name         =>  cv_msg_xxcmm_00309,         -- ���b�Z�[�W�R�[�h
                        iv_token_name1  =>  cv_tkn_cust_code,           -- �g�[�N���R�[�h1
                        iv_token_value1 =>  iv_rec.cust_code            -- �g�[�N���l1
                      );
      ov_errmsg   :=  lv_errmsg;
      lv_errbuf   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_ccp,          -- �A�v���P�[�V�����Z�k��
                        iv_name         =>  cv_msg_xxccp_91003        -- ���b�Z�[�W�R�[�h
                      );
      ov_errbuf   := lv_errbuf || cv_msg_bracket_f || 
                     cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || cv_msg_bracket_t;
      -- �����X�e�[�^�X�Z�b�g
      ov_retcode  :=  cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_upd_hz_parties;
--
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_upd_xxcmm_cust_accounts
   * Description      : �ŏI������X�V(A-4)
   ***********************************************************************************/
  PROCEDURE prc_upd_xxcmm_cust_accounts(
    iv_rec        IN  XXCMM003A15C_cur%ROWTYPE,   -- �����Ώۃf�[�^���R�[�h
    ov_errbuf     OUT VARCHAR2,                   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,                   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_upd_xxcmm_cust_accounts'; -- �v���O������
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
    lv_step                   VARCHAR2(10);                                   -- �X�e�b�v
    ld_past_final_tran_date   xxcmm_cust_accounts.past_final_tran_date%TYPE;  -- �O���ŏI�����
-- 2009/05/25 Ver1.2 delete start by Yutaka.Kuboshima
--    ld_final_call_date        xxcmm_cust_accounts.final_call_date%TYPE;       -- �ŏI�K���
-- 2009/05/25 Ver1.2 delete end by Yutaka.Kuboshima
    ld_cnvs_date              xxcmm_cust_accounts.cnvs_date%TYPE;             -- �ڋq�l����
    ld_start_tran_date        xxcmm_cust_accounts.start_tran_date%TYPE;       -- ��������
-- 2009/05/27 Ver1.2 ��QT1_0816 add start by Yutaka.Kuboshima
    ld_final_tran_date        xxcmm_cust_accounts.final_tran_date%TYPE;       -- �ŏI�����
-- 2009/05/27 Ver1.2 ��QT1_0816 add end by Yutaka.Kuboshima
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
    -- �X�V���ڕҏW
    --
-- 2009/05/27 Ver1.2 ��QT1_0816 add start by Yutaka.Kuboshima
    -- �ŏI�����
    lv_step := 'A-4.1';
    IF (iv_rec.final_tran_date > iv_rec.new_tran_date) 
      OR (iv_rec.new_tran_date IS NULL)
    THEN
      ld_final_tran_date := iv_rec.final_tran_date;
    ELSE
      ld_final_tran_date := iv_rec.new_tran_date;
    END IF;
-- 2009/05/27 Ver1.2 ��QT1_0816 add end by Yutaka.Kuboshima
    -- �O���ŏI�����
-- 2009/05/27 Ver1.2 ��QT1_0816 modify start by Yutaka.Kuboshima
--    lv_step := 'A-4.1';
    lv_step := 'A-4.2';
-- 2009/05/27 Ver1.2 ��QT1_0816 modify end by Yutaka.Kuboshima
    IF (gv_prev_month_cls_status = cv_cal_status_close) THEN
      ld_past_final_tran_date :=  iv_rec.past_final_tran_date;
    ELSE
-- 2009/12/16 Ver1.4 E_�{�ғ�_00540 modify start by Yutaka.Kuboshima
--      ld_past_final_tran_date :=  iv_rec.past_new_fnl_trn_dt;
      -- �O���ŐV��������O���ŏI�������薢���̏ꍇ�͍X�V
      IF (iv_rec.past_new_fnl_trn_dt > NVL(iv_rec.past_final_tran_date, cd_min_date)) THEN
        ld_past_final_tran_date :=  iv_rec.past_new_fnl_trn_dt;
      ELSE
        ld_past_final_tran_date :=  iv_rec.past_final_tran_date;
      END IF;
-- 2009/12/16 Ver1.4 E_�{�ғ�_00540 modify end by Yutaka.Kuboshima
    END IF;
    -- �ŏI�K���
-- 2009/05/27 Ver1.2 delete start by Yutaka.Kuboshima
--    lv_step := 'A-4.2';
--    IF ((iv_rec.cust_status = cv_cust_status_admit) AND (iv_rec.new_tran_date > iv_rec.final_call_date)) THEN
--      ld_final_call_date  :=  iv_rec.new_tran_date;
--    ELSE
--      ld_final_call_date  :=  iv_rec.final_call_date;
--    END IF;
-- 2009/05/27 Ver1.2 delete end by Yutaka.Kuboshima
    -- �ڋq�l����
    lv_step := 'A-4.3';
-- 2009/05/27 Ver1.2 ��QT1_0811,T1_0863 modify start by Yutaka.Kuboshima
--    IF ((iv_rec.business_mid_type = cv_gyotai_chu_vd) AND (iv_rec.cnvs_date IS NULL)) THEN
--      ld_cnvs_date  :=  iv_rec.new_tran_date;
--    ELSE
--      IF (iv_rec.cust_status = cv_cust_status_admit) THEN
--        IF (iv_rec.new_tran_date > iv_rec.final_call_date) THEN
--          ld_cnvs_date  :=  iv_rec.new_tran_date;
--        ELSE
--          ld_cnvs_date  :=  iv_rec.final_call_date;
--        END IF;
--      ELSE
--        ld_cnvs_date  :=  iv_rec.cnvs_date;
--      END IF;
--    END IF;
    IF (iv_rec.cnvs_date IS NULL)
      AND (iv_rec.cust_status = cv_cust_status_admit)
        AND (iv_rec.business_low_type NOT IN (cv_gyotai_sho_vd24, cv_gyotai_sho_vd25))
    THEN
      ld_cnvs_date := iv_rec.old_tran_date;
    ELSE
      ld_cnvs_date := iv_rec.cnvs_date;
    END IF;
-- 2009/05/27 Ver1.2 ��QT1_0811,T1_0863 modify end by Yutaka.Kuboshima
    -- ��������
    lv_step := 'A-4.4';
    IF (iv_rec.start_tran_date IS NULL) THEN
      ld_start_tran_date    :=  iv_rec.new_tran_date;
    ELSE
      ld_start_tran_date    :=  iv_rec.start_tran_date;
    END IF;
    --
    -- �ŏI������X�VSQL��
    --
    lv_step := 'A-4.5';
    --
    UPDATE
      -- �ڋq�ǉ����
      xxcmm_cust_accounts         xcac
    SET
-- 2009/05/27 Ver1.2 ��QT1_0816 modify start by Yutaka.Kuboshima
--      xcac.final_tran_date        = iv_rec.new_tran_date,         -- �ŏI�����
      xcac.final_tran_date        = ld_final_tran_date,           -- �ŏI�����
-- 2009/05/27 Ver1.2 ��QT1_0816 modify end by Yutaka.Kuboshima
      xcac.past_final_tran_date   = ld_past_final_tran_date,      -- �O���ŏI�����
-- 2009/05/27 Ver1.2 delete start by Yutaka.Kuboshima
--      xcac.final_call_date        = ld_final_call_date,           -- �ŏI�K���
-- 2009/05/27 Ver1.2 delete start by Yutaka.Kuboshima
      xcac.cnvs_date              = ld_cnvs_date,                 -- �ڋq�l����
      xcac.start_tran_date        = ld_start_tran_date,           -- ��������
      -- WHO
      xcac.last_updated_by        = cn_last_updated_by,           -- �ŏI�X�V��
      xcac.last_update_date       = cd_last_update_date,          -- �ŏI�X�V��
      xcac.last_update_login      = cn_last_update_login,         -- �ŏI�X�V���O�C��
      xcac.request_id             = cn_request_id,                -- �v��ID
      xcac.program_application_id = cn_program_application_id,    -- �ݶ��ĥ��۸��ѥ���ع����ID
      xcac.program_id             = cn_program_id,                -- �ݶ��ĥ��۸���ID
      xcac.program_update_date    = cd_program_update_date        -- �v���O�����X�V��
    WHERE
          xcac.rowid              = iv_rec.xcac_rowid             -- ���R�[�hID�i�ڋq�ǉ����j
    ;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_cmm,            -- �A�v���P�[�V�����Z�k��
                        iv_name         =>  cv_msg_xxcmm_00311,         -- ���b�Z�[�W�R�[�h
                        iv_token_name1  =>  cv_tkn_ng_table,            -- �g�[�N���R�[�h1
                        iv_token_value1 =>  cv_tbl_nm_xcac,             -- �g�[�N���l1
                        iv_token_name2  =>  cv_tkn_cust_code,           -- �g�[�N���R�[�h2
                        iv_token_value2 =>  iv_rec.cust_code,           -- �g�[�N���l2
                        iv_token_name3  =>  cv_tkn_fnl_trn_date,        -- �g�[�N���R�[�h3
                        iv_token_value3 =>  TO_CHAR(iv_rec.new_tran_date, cv_date_fmt) -- �g�[�N���l3
                      );
      ov_errmsg   :=  lv_errmsg;
      lv_errbuf   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_ccp,          -- �A�v���P�[�V�����Z�k��
                        iv_name         =>  cv_msg_xxccp_91003        -- ���b�Z�[�W�R�[�h
                      );
      ov_errbuf   := lv_errbuf || cv_msg_bracket_f || 
                     cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || cv_msg_bracket_t;
      -- �����X�e�[�^�X�Z�b�g
      ov_retcode  :=  cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_upd_xxcmm_cust_accounts;
--
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE prc_init(
    iv_proc_date_from   IN    VARCHAR2,   -- ������
    iv_proc_date_to     IN    VARCHAR2,   -- ������
    ov_errbuf           OUT   VARCHAR2,   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT   VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT   VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_init'; -- �v���O������
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
    lv_step                   VARCHAR2(10);   -- �X�e�b�v
    lv_now_proc_date          VARCHAR2(10);   -- �Ɩ����t�i������j
    lv_proc_date              VARCHAR2(10);   -- �p�����[�^������
    ld_now_proc_date          DATE;           -- �Ɩ����t
    ld_prev_proc_date         DATE;           -- �O�Ɩ����t
    lv_para_edit_buf          VARCHAR2(60);   -- �o�͗p���Ұ�������ҏW�̈�
    lv_ar_set_of_books_nm     gl_sets_of_books.name%TYPE;             -- �c�ƃV�X�e����v�����`��
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
    -- �v���t�@�C���l�擾
    --
    lv_step := 'A-1.1';
    -- �V�X�e���ғ����J�����_�R�[�h�擾
    gv_cal_code := fnd_profile.value(cv_profile_ctrl_cal);
    IF (gv_cal_code IS NULL) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  cv_apl_name_cmm,      -- �A�v���P�[�V�����Z�k��
                      iv_name           =>  cv_msg_xxcmm_00002,   -- �v���t�@�C���擾�G���[
                      iv_token_name1    =>  cv_tkn_ng_profile,    -- �g�[�N��(NG_PROFILE)
                      iv_token_value1   =>  cv_profile_ctrl_cal   -- �v���t�@�C����`��
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- ��v�J�����_�R�[�h�擾
    gv_gl_cal_code := fnd_profile.value(cv_profile_gl_cal);
    IF (gv_gl_cal_code IS NULL) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  cv_apl_name_cmm,      -- �A�v���P�[�V�����Z�k��
                      iv_name           =>  cv_msg_xxcmm_00002,   -- �v���t�@�C���擾�G���[
                      iv_token_name1    =>  cv_tkn_ng_profile,    -- �g�[�N��(NG_PROFILE)
                      iv_token_value1   =>  cv_profile_gl_cal     -- �v���t�@�C����`��
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- �c�ƃV�X�e����v�����`���擾
    lv_ar_set_of_books_nm := fnd_profile.value(cv_profile_ar_bks);
    IF (lv_ar_set_of_books_nm IS NULL) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  cv_apl_name_cmm,      -- �A�v���P�[�V�����Z�k��
                      iv_name           =>  cv_msg_xxcmm_00002,   -- �v���t�@�C���擾�G���[
                      iv_token_name1    =>  cv_tkn_ng_profile,    -- �g�[�N��(NG_PROFILE)
                      iv_token_value1   =>  cv_profile_ar_bks     -- �v���t�@�C����`��
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    --
    -- �Ɩ����t�擾
    --
    lv_step := 'A-1.2';
    --
    ld_now_proc_date    :=  xxccp_common_pkg2.get_process_date;
    gd_now_proc_date    :=  ld_now_proc_date;
    -- ������(To)���O���[�o���ϐ��Ɋi�[
    IF (iv_proc_date_to IS NULL) THEN
      gd_para_proc_date_t   :=  TO_DATE(TO_CHAR(ld_now_proc_date, cv_date_fmt) || cv_time_max, cv_date_time_fmt);
    ELSE
      gd_para_proc_date_t   :=  TO_DATE(iv_proc_date_to || cv_time_max, cv_date_time_fmt);
    END IF;
    --
    -- �O�Ɩ����t�擾
    --
    lv_step := 'A-1.3';
    --
    ld_prev_proc_date   :=  xxccp_common_pkg2.get_working_day(
                              gd_now_proc_date,
                              -1,
                              gv_cal_code
                            );
    ld_prev_proc_date   :=  TRUNC(ld_prev_proc_date + 1);
    --
    -- ������(From)���O���[�o���ϐ��Ɋi�[
    IF (iv_proc_date_from IS NULL) THEN
      gd_para_proc_date_f   :=  ld_prev_proc_date;
    ELSE
      gd_para_proc_date_f   :=  TO_DATE(iv_proc_date_from, cv_date_fmt);
    END IF;
    lv_step := 'A-1.4';
    --
    -- �R���J�����g�E�p�����[�^�̃��O�o��
    -- ������(From)
    lv_para_edit_buf    :=  cv_para01_name    ||  cv_msg_part       ||
                            cv_msg_bracket_f  ||  iv_proc_date_from ||  cv_msg_bracket_t;
    -- ������(From)�̎����擾�l
    IF (iv_proc_date_from IS NULL) THEN
      lv_para_edit_buf  :=  lv_para_edit_buf  ||  cv_msg_part       ||  cv_para_at_name     ||
                            cv_msg_bracket_f  ||  TO_CHAR(gd_para_proc_date_f, cv_date_fmt) ||  cv_msg_bracket_t;
    END IF;
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => lv_para_edit_buf
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => lv_para_edit_buf
    );
    -- ������(To)
    lv_para_edit_buf    :=  cv_para02_name    ||  cv_msg_part       ||
                            cv_msg_bracket_f  ||  iv_proc_date_to   ||  cv_msg_bracket_t;
    -- ������(To)�̎����擾�l
    IF (iv_proc_date_to IS NULL) THEN
      lv_para_edit_buf  :=  lv_para_edit_buf  ||  cv_msg_part       ||  cv_para_at_name     ||
                            cv_msg_bracket_f  ||  TO_CHAR(gd_para_proc_date_t, cv_date_fmt) ||  cv_msg_bracket_t;
    END IF;
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => lv_para_edit_buf
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => lv_para_edit_buf
    );
    -- ��s�}��
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => ''
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => ''
    );
    --
    --
    -- �p�����[�^�`�F�b�N�i�������j
    --
    lv_step := 'A-1.5';
    IF (gd_para_proc_date_f > gd_para_proc_date_t) THEN
      -- �p�����[�^�́u������(From)�v�� �u������(To)�v�ł���ꍇ�A�G���[
      -- ���b�Z�[�W�擾
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_cmm,      -- �A�v���P�[�V�����Z�k��
                        iv_name         =>  cv_msg_xxcmm_00305    -- ���b�Z�[�W�R�[�h
                      );
      -- �p�����[�^�G���[��O
      RAISE global_check_para_expt;
      --
    END IF;
    --
    -- �O����v���Ԃ̃N���[�Y�X�e�[�^�X���擾
    --
    lv_step := 'A-1.6';
    --
    gv_prev_month_cls_status  :=  NULL;
    --
    BEGIN
    --
      SELECT
        pers.closing_status
      INTO
        gv_prev_month_cls_status
      FROM
        gl_periods              peri,     -- ��v�J�����_
        gl_period_statuses      pers      -- ��v�J�����_�X�e�[�^�X
      WHERE
            EXISTS(
              -- AR�A�v���P�[�V�����̃J�����_�𒊏o
              SELECT
                'X'
              FROM
                fnd_application   fapl
              WHERE
                    fapl.application_id         = pers.application_id
                AND fapl.application_short_name = cv_apl_short_nm_ar
            )
        AND EXISTS(
              -- �c�ƃV�X�e����v����ID�̃J�����_�𒊏o
              SELECT
                'X'
              FROM
                gl_sets_of_books  gsob
              WHERE
                    gsob.set_of_books_id  = pers.set_of_books_id
                AND gsob.name             = lv_ar_set_of_books_nm
            )
        AND peri.period_name              = pers.period_name
        AND peri.period_set_name          = gv_gl_cal_code
        AND peri.adjustment_period_flag   = cv_flag_no
        AND pers.adjustment_period_flag   = cv_flag_no
        AND ADD_MONTHS(gd_now_proc_date, -1) BETWEEN pers.start_date AND pers.end_date
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_cmm,          -- �A�v���P�[�V�����Z�k��
                        iv_name         =>  cv_msg_xxcmm_00331        -- ���b�Z�[�W�R�[�h
                      );
        lv_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg;
        RAISE global_process_expt;
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_ccp,          -- �A�v���P�[�V�����Z�k��
                        iv_name         =>  cv_msg_xxccp_91003        -- ���b�Z�[�W�R�[�h
                      );
        lv_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
        RAISE global_process_expt;
    END;
    --
    -- �O������
    lv_step := 'A-1.7';
    --
    gd_last_month_day   :=  LAST_DAY(ADD_MONTHS(gd_now_proc_date, -1));
    --
    --
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** �p�����[�^�G���[��O�n���h�� ***
    WHEN global_check_para_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** �������ʗ�O�n���h�� **
    WHEN global_process_expt THEN
      -- ���b�Z�[�W�Z�b�g
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_apl_name_ccp,          -- �A�v���P�[�V�����Z�k��
                      iv_name         =>  cv_msg_xxccp_91003        -- ���b�Z�[�W�R�[�h
                    );
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_init;
--
--
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_proc_date_from   IN  VARCHAR2,   -- �R���J�����g�E�p�����[�^ ������(From)
    iv_proc_date_to     IN  VARCHAR2,   -- �R���J�����g�E�p�����[�^ ������(To)
    ov_errbuf           OUT VARCHAR2,   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
    lv_step       VARCHAR2(10);     -- �X�e�b�v
--
    -- *** ���[�J���ϐ� ***
    lb_err_flg    BOOLEAN;          -- �G���[�L��
    ln_err_cnt    NUMBER;           -- �G���[�������i�P�ڋq�P�ʁj
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    XXCMM003A15C_rec    XXCMM003A15C_cur%ROWTYPE;
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
    gn_target_cnt           :=  0;
    gn_normal_cnt           :=  0;
    gn_error_cnt            :=  0;
    gn_warn_cnt             :=  0;
    gn_xx_cust_acnt_upd_cnt :=  0;
    gn_hz_pts_upd_cnt       :=  0;
--
    -- �G���[�L����������
    lb_err_flg := FALSE;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- A-1.����������
    -- ===============================
    lv_step := 'A-1';
    prc_init(
      iv_proc_date_from,  -- ������(From)
      iv_proc_date_to,    -- ������(To)
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================
    -- A-2.�����Ώۃf�[�^���o
    -- ===============================
    lv_step := 'A-2';
    --
    OPEN  XXCMM003A15C_cur;
    --
    LOOP
      -- �����Ώۃf�[�^�E�J�[�\���t�F�b�`
      FETCH XXCMM003A15C_cur INTO XXCMM003A15C_rec;
      EXIT WHEN XXCMM003A15C_cur%NOTFOUND;
      --
      gn_target_cnt := XXCMM003A15C_cur%ROWCOUNT;
      ln_err_cnt    := 0;
      --
      -- ===============================
      -- A-3.SAVE POINT ���s
      -- ===============================
      lv_step := 'A-3';
      --
      SAVEPOINT svpt_cust_rec;
      --
      -- ===============================
      -- A-4.�ŏI������X�V
      -- ===============================
      lv_step := 'A-4';
      prc_upd_xxcmm_cust_accounts(
        XXCMM003A15C_rec,   -- �J�[�\�����R�[�h
        lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> cv_status_normal) THEN
        lb_err_flg  :=  TRUE;
        ln_err_cnt  :=  1;
        fnd_file.put_line(
          which => fnd_file.output,
          buff  => lv_errmsg --���[�U�[�G���[���b�Z�[�W
        );
        fnd_file.put_line(
          which => fnd_file.log,
          buff  => lv_errmsg --���[�U�[�G���[���b�Z�[�W
        );
        fnd_file.put_line(
          which => fnd_file.log,
          buff  => lv_errbuf --�G���[���b�Z�[�W
        );
        -- ���b�Z�[�W�ҏW�̈揉����
        lv_errmsg := NULL;
        lv_errbuf := NULL;
        --
      ELSE
        -- �ڋq�ǉ����X�V�����J�E���g
        gn_xx_cust_acnt_upd_cnt := gn_xx_cust_acnt_upd_cnt + 1;
      END IF;
      --
-- 2009/03/02 modify start
      IF (XXCMM003A15C_rec.cust_status = cv_cust_status_admit) --THEN
        AND (ln_err_cnt = 0)
      THEN
-- 2009/03/02 modify end
        -- ===============================
        -- A-5.�ڋq�X�e�[�^�X�X�V
        -- ===============================
        lv_step := 'A-5';
        --
        prc_upd_hz_parties(
          XXCMM003A15C_rec,   -- �J�[�\�����R�[�h
          lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode <> cv_status_normal) THEN
          lb_err_flg  :=  TRUE;
          ln_err_cnt  :=  1;
          fnd_file.put_line(
            which => fnd_file.output,
            buff  => lv_errmsg --���[�U�[�G���[���b�Z�[�W
          );
          fnd_file.put_line(
            which => fnd_file.log,
            buff  => lv_errmsg --���[�U�[�G���[���b�Z�[�W
          );
          fnd_file.put_line(
            which => fnd_file.log,
            buff  => lv_errbuf --�G���[���b�Z�[�W
          );
          -- ���b�Z�[�W�ҏW�̈揉����
          lv_errmsg := NULL;
          lv_errbuf := NULL;
          --
          -- �ڋq�ǉ����X�V�����J�E���g��߂�
          gn_xx_cust_acnt_upd_cnt := gn_xx_cust_acnt_upd_cnt - 1;
          --
        ELSE
          -- �p�[�e�B�X�V�i�ڋq�X�e�[�^�X�j����
          gn_hz_pts_upd_cnt := gn_hz_pts_upd_cnt + 1;
        END IF;
        --
      END IF;
      --
      -- ���������A�G���[�����̃J�E���g
      IF (ln_err_cnt = 0) THEN
        gn_normal_cnt := gn_normal_cnt + 1;
      ELSE
        gn_error_cnt  := gn_error_cnt + ln_err_cnt;
      END IF;
      --
      -- �G���[���o���ASAVEPOINT�܂�ROLLBACK
      IF (ln_err_cnt > 0) THEN
        -- ===============================
        -- A-7.ROLLBACK���s����
        -- ===============================
        lv_step := 'A-7';
        --
        ROLLBACK TO svpt_cust_rec;
        --
      END IF;
      --
    END LOOP;
    --
    -- �J�[�\���N���[�Y
    CLOSE XXCMM003A15C_cur;
    --
    IF (lb_err_flg = FALSE) THEN
      -- �Ώۃf�[�^�Ȃ����̃��b�Z�[�W
      IF (gn_target_cnt = 0) THEN
        -- ���b�Z�[�W�Z�b�g
        lv_errmsg   :=  xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_apl_name_cmm,        -- �A�v���P�[�V�����Z�k��
                          iv_name         =>  cv_msg_xxcmm_00001      -- ���b�Z�[�W�R�[�h
                        );
        fnd_file.put_line(
          which => fnd_file.output,
          buff  => lv_errmsg --�p�����[�^�Ȃ����b�Z�[�W
        );
        fnd_file.put_line(
          which => fnd_file.log,
          buff  => lv_errmsg --�p�����[�^�Ȃ����b�Z�[�W
        );
      END IF;
    ELSE
      -- �X�V�G���[���������Ă���ׁA�G���[���Z�b�g
      ov_retcode := cv_status_error;
    END IF;
  --
  EXCEPTION
    -- *** �C�ӂŗ�O�������L�q���� ****
    -- �J�[�\���̃N���[�Y�������ɋL�q����
    -- *** �p�����[�^�G���[��O�n���h�� ***
    -- *** ���b�N�G���[��O�n���h�� ***
    WHEN global_check_lock_expt THEN
      -- �J�[�\���N���[�Y
      IF XXCMM003A15C_cur%ISOPEN THEN
        CLOSE  XXCMM003A15C_cur;
      END IF;
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_cmm,        -- �A�v���P�[�V�����Z�k��
                        iv_name         =>  cv_msg_xxcmm_00008,     -- ���b�Z�[�W�R�[�h
                        iv_token_name1  =>  cv_tkn_ng_table,        -- �g�[�N���R�[�h1
                        iv_token_value1 =>  cv_tbl_nm_xcac          -- �g�[�N���l1
                      );
      lv_errbuf   :=  lv_errmsg;
      ov_errmsg   :=  lv_errmsg;
      ov_errbuf   :=  cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      -- �����X�e�[�^�X�Z�b�g
      ov_retcode  :=  cv_status_error;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\���N���[�Y
      IF XXCMM003A15C_cur%ISOPEN THEN
        CLOSE XXCMM003A15C_cur;
      END IF;
      -- ���b�Z�[�W�Z�b�g
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      -- �����X�e�[�^�X�Z�b�g
      ov_retcode := cv_status_error;
      --
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF XXCMM003A15C_cur%ISOPEN THEN
        CLOSE XXCMM003A15C_cur;
      END IF;
      -- ���b�Z�[�W�Z�b�g
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_apl_name_ccp,          -- �A�v���P�[�V�����Z�k��
                      iv_name         =>  cv_msg_xxccp_91003        -- ���b�Z�[�W�R�[�h
                    );
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      -- �����X�e�[�^�X�Z�b�g
      ov_retcode := cv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
--
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf            OUT   VARCHAR2,     -- �G���[�E���b�Z�[�W  --# �Œ� #
    retcode           OUT   VARCHAR2,     -- ���^�[���E�R�[�h    --# �Œ� #
    iv_proc_date_from IN    VARCHAR2,     -- �R���J�����g�E�p�����[�^������(FROM)
    iv_proc_date_to   IN    VARCHAR2      -- �R���J�����g�E�p�����[�^������(TO)
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
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_all_error_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cv_prt_error_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90007'; -- �G���[�I���ꕔ����
    --
    cv_log             CONSTANT VARCHAR2(100) := 'LOG';              -- ���O
    cv_output          CONSTANT VARCHAR2(100) := 'OUTPUT';           -- �A�E�g�v�b�g
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
    ----------------------------------
    -- ���O�w�b�_�o��
    ----------------------------------
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
      iv_which   => cv_log,
      ov_retcode => lv_retcode,
      ov_errbuf  => lv_errbuf,
      ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
    xxccp_common_pkg.put_log_header(
      iv_which   => cv_output,
      ov_retcode => lv_retcode,
      ov_errbuf  => lv_errbuf,
      ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_proc_date_from,    -- �R���J�����g�E�p�����[�^������(FROM)
      iv_proc_date_to,      -- �R���J�����g�E�p�����[�^������(TO)
      lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      IF (LENGTHB(TRIM(lv_errmsg)) > 0) THEN
        fnd_file.put_line(
          which  => fnd_file.output,
          buff   => LTRIM(lv_errmsg)   --���[�U�[�E�G���[���b�Z�[�W
        );
        fnd_file.put_line(
          which  => fnd_file.log,
          buff   => LTRIM(lv_errmsg)   --���[�U�[�E�G���[���b�Z�[�W
        );
      END IF;
      IF (LENGTHB(TRIM(lv_errbuf)) > 0) THEN
        fnd_file.put_line(
          which  => fnd_file.log,
          buff   => LTRIM(lv_errbuf)   --�G���[���b�Z�[�W
        );
      END IF;
    END IF;
    --��s�}��
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => ''
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name,
                     iv_name         => cv_target_rec_msg,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => gv_out_msg
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name,
                     iv_name         => cv_success_rec_msg,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => gv_out_msg
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => gv_out_msg
    );
    --
    --�ڋq�ǉ����X�V�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_apl_name_cmm,
                     iv_name         => cv_msg_xxcmm_00033,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR(gn_xx_cust_acnt_upd_cnt),
                     iv_token_name2  => cv_tkn_table,
                     iv_token_value2 => cv_tbl_nm_xcac
                   );
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => gv_out_msg
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => gv_out_msg
    );
    --
    --�p�[�e�B�X�V�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_apl_name_cmm,
                     iv_name         => cv_msg_xxcmm_00033,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR(gn_hz_pts_upd_cnt),
                     iv_token_name2  => cv_tkn_table,
                     iv_token_value2 => cv_tbl_nm_hzpt
                   );
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => gv_out_msg
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name,
                     iv_name         => cv_error_rec_msg,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => gv_out_msg
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => gv_out_msg
    );
    --�󔒍s�o��
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => ''
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => ''
    );
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      IF (gn_normal_cnt > 0) THEN
        lv_message_code := cv_prt_error_msg;
      ELSE
        lv_message_code := cv_all_error_msg;
      END IF;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name,
                     iv_name         => lv_message_code
                   );
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => gv_out_msg
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�R�~�b�g
    COMMIT;
    --
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxcmm003a15c;
/
