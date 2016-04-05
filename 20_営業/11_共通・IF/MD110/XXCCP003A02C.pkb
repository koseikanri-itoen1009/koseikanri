CREATE OR REPLACE PACKAGE BODY APPS.XXCCP003A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCCP003A02C(body)
 * Description      : �≮���m��f�[�^�o��
 * MD.070           : �≮���m��f�[�^�o�� (MD070_IPO_CCP_003_A02)
 * Version          : 1.0
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
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �x������
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
    ld_process_date  DATE := xxccp_common_pkg2.get_process_date; -- �Ɩ����t
    lt_sales_ou_id   hr_operating_units.organization_id%TYPE;    -- �c�Ƒg�DID
--
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
                 ,xwbl.selling_month                                AS selling_month
                 ,xwbh.cust_code                                    AS cust_code
                 ,SUM( xwbl.demand_amt )                            AS demand_amt
                 ,SUM( xwbl.payment_amt )                           AS payment_amt
                 ,xwbl.status                                       AS status
           FROM   xxcok_wholesale_bill_head  xwbh  -- �≮�������w�b�_
                 ,xxcok_wholesale_bill_line  xwbl  -- �≮����������
                 ,po_vendors                 pv    -- �d����}�X�^
                 ,po_vendor_sites_all        pvs   -- �d����T�C�g
           WHERE  xwbl.wholesale_bill_header_id   =  xwbh.wholesale_bill_header_id
             AND  xwbl.payment_amt                <> 0
             AND  pv.segment1                     =  xwbh.supplier_code
             AND  pvs.vendor_id                   =  pv.vendor_id
             AND  pvs.org_id                      =  lt_sales_ou_id  -- �c�Ƒg�DID
             AND  (     pvs.inactive_date         IS NULL
                    OR  pvs.inactive_date         <  ld_process_date
                  )
             AND  xwbh.expect_payment_date        >= TO_DATE( iv_payment_date_from ,'YYYY/MM/DD HH24:MI:SS' )
             AND  xwbh.expect_payment_date        <= TO_DATE( iv_payment_date_to   ,'YYYY/MM/DD HH24:MI:SS' )
           GROUP BY xwbh.base_code            -- ���_CD
                   ,xwbh.supplier_code        -- �d����CD
                   ,pvs.attribute1            -- �d���於
                   ,xwbh.expect_payment_date  -- �x���\���
                   ,xwbl.selling_month        -- ����N��
                   ,xwbh.cust_code            -- �ڋqCD
                   ,xwbl.status               -- �X�e�[�^�X
          )
      SELECT wv.base_code            AS base_code
            ,bv.base_name            AS base_name
            ,wv.supplier_code        AS supplier_code
            ,wv.supplier_name        AS supplier_name
            ,wv.expect_payment_date  AS expect_payment_date
            ,wv.selling_month        AS selling_month
            ,wv.cust_code            AS cust_code
            ,cv.cust_name            AS cust_name
            ,wv.demand_amt           AS demand_amt
            ,wv.payment_amt          AS payment_amt
            ,wv.status               AS status
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
              ,wv.selling_month        -- ����N��
              ,wv.cust_code            -- �ڋqCD
      ;
    -- ���C���J�[�\�����R�[�h�^
    main_rec  main_cur%ROWTYPE;
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
        ,buff   =>           '"' || '���_CD'                     || '"' -- ���_CD
                   || ',' || '"' || '���_��'                     || '"' -- ���_��
                   || ',' || '"' || '�d����CD'                   || '"' -- �d����CD
                   || ',' || '"' || '�d���於'                   || '"' -- �d���於
                   || ',' || '"' || '�x���\���'                 || '"' -- �x���\���
                   || ',' || '"' || '����Ώ۔N��'               || '"' -- ����Ώ۔N��
                   || ',' || '"' || '�ڋqCD'                     || '"' -- �ڋqCD
                   || ',' || '"' || '�ڋq��'                     || '"' -- �ڋq��
                   || ',' || '"' || '�������z'                   || '"' -- �������z
                   || ',' || '"' || '�x�����z'                   || '"' -- �x�����z
                   || ',' || '"' || '�X�e�[�^�X'                 || '"' -- �X�e�[�^�X
                   || ',' || '"' || '�X�e�[�^�X��'               || '"' -- �X�e�[�^�X��
      );
      -- �f�[�^���o��(CSV)
      FOR main_rec IN main_cur( iv_payment_date_from, iv_payment_date_to ) LOOP
        --�����Z�b�g
        gn_target_cnt := gn_target_cnt + 1;
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   =>         '"' || main_rec.base_code           || '"' -- ���_CD
                   || ',' || '"' || main_rec.base_name           || '"' -- ���_��
                   || ',' || '"' || main_rec.supplier_code       || '"' -- �d����CD
                   || ',' || '"' || main_rec.supplier_name       || '"' -- �d���於
                   || ',' || '"' || main_rec.expect_payment_date || '"' -- �x���\���
                   || ',' || '"' || main_rec.selling_month       || '"' -- ����Ώ۔N��
                   || ',' || '"' || main_rec.cust_code           || '"' -- �ڋqCD
                   || ',' || '"' || main_rec.cust_name           || '"' -- �ڋq��
                   || ',' || '"' || main_rec.demand_amt          || '"' -- �������z
                   || ',' || '"' || main_rec.payment_amt         || '"' -- �x�����z
                   || ',' || '"' || main_rec.status              || '"' -- �X�e�[�^�X
                   || ',' || '"' || main_rec.status_name         || '"' -- �X�e�[�^�X��
        );
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