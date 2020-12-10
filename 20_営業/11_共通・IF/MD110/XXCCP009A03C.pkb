CREATE OR REPLACE PACKAGE BODY APPS.XXCCP009A03C
AS
/*****************************************************************************************
 *
 * Package Name     : XXCCP009A03C(body)
 * Description      : �������ۗ��X�e�[�^�X�X�V����
 * Version          : 1.2
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- ------------------------------------------------------------
 *  submain                  ���C�������v���V�[�W��
 *  main                     �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014/10/30    1.0   SCSK K.Nakatsu  [E_�{�ғ�_11000]�V�K�쐬
 *  2015/01/08    1.1   SCSK T.Ishiwata [E_�{�ғ�_11000]�đΉ�
 *  2020/12/01    1.2   SCSK R.Oikawa   [E_�{�ғ�_16800]�p�t�H�[�}���X�Ή�
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
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
  -- �A�v���P�[�V�����Z�k��
  cv_appl_short_name_xxccp  CONSTANT VARCHAR2(10) := 'XXCCP';
  -- �p�b�P�[�W��
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCCP009A03C'; -- �p�b�P�[�W��
  -- ���s���[�h
  cv_execmode_chk           CONSTANT VARCHAR2(1)  := '0'; -- ���O�o�͂̂�
  cv_execmode_upd           CONSTANT VARCHAR2(1)  := '1'; -- ���O�o�͂���уf�[�^�X�V
  -- �������ۗ��X�e�[�^�X �Q��
  cv_invhold_lookuptype     CONSTANT VARCHAR2(25) := 'XX03_AR_INV_HOLD_STATUS';
  cv_invhold_lang           CONSTANT VARCHAR2(2)  := USERENV('LANG');
  cv_invhold_flag           CONSTANT VARCHAR2(1)  := 'Y';
  -- ���O�C�����[�UORG_ID
  cn_org_id                 CONSTANT NUMBER       := fnd_global.org_id;
  -- �R���J�����g�v���O�����\
  cv_concprg_lang           CONSTANT VARCHAR2(2)  := USERENV('LANG');
  -- ������
  cv_raa_stat               CONSTANT VARCHAR2(3)  := 'APP';
  cv_raa_disp               CONSTANT VARCHAR2(1)  := 'Y';
  -- ���t����
  cv_date_format            CONSTANT VARCHAR2(21) := 'RRRR/MM/DD HH24:MI:SS';
  cv_date_format2           CONSTANT VARCHAR2(10) := 'RRRR/MM/DD';
--
--
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  TYPE request_ids_rtype IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  gv_exe_mode               VARCHAR2(30);
  gv_bill_cust_code         VARCHAR2(30);
  gd_target_date            DATE;
  gd_business_date          DATE;
  gn_request_id             request_ids_rtype;
  gv_status_from            VARCHAR2(30);
  gv_status_to              VARCHAR2(30);
--
  gv_status                 VARCHAR2(30);
--
  --==================================================
  -- �O���[�o���J�[�\��
  --==================================================
  CURSOR target_cur(
      in_request_id NUMBER
  ) IS
-- 2020/12/01 Ver.1.2 Mod Start
--    SELECT   rcta.attribute7             AS e_attribute7            -- �������ۗ��X�e�[�^�X
    SELECT  /*+ LEADING(inv)
            INDEX(rcta RA_CUSTOMER_TRX_U1)*/
             rcta.attribute7             AS e_attribute7            -- �������ۗ��X�e�[�^�X
-- 2020/12/01 Ver.1.2 Mod End
            ,rcta.trx_number             AS e_trx_number            -- ����ԍ�
            ,rcta.trx_date               AS e_trx_date              -- �����
            ,rctta.name                  AS e_name                  -- ����^�C�v
            ,rctta.attribute1            AS e_attribute1            -- �������o�͑Ώۋ敪
            ,(SELECT fcpt.user_concurrent_program_name
              FROM   fnd_concurrent_programs_tl   fcpt
              WHERE  1 = 1
              AND    fcpt.application_id        = rcta.program_application_id
              AND    fcpt.concurrent_program_id = rcta.program_id
              AND    fcpt.language              = cv_concprg_lang
             )                           AS e_conc_name             -- �ŏI�X�V�v���O������(�������׃f�[�^�쐬���Ώ�)
            ,rcta.request_id             AS e_request_id            -- �ŏI�X�V�v��ID
            ,rcta.last_update_date       AS e_last_update_date      -- �ŏI�X�V��
            ,hca.account_number          AS e_account_number        -- �����ڋq�ԍ�
            ,hp.party_name               AS e_party_name            -- �����ڋq��
            ,apsa.amount_due_original    AS e_amount_due_original   -- �������������z
            ,apsa.amount_due_remaining   AS e_amount_due_remaining  -- ������c��
            ,apsa.amount_applied         AS e_amount_applied        -- �����ώc��
            ,apsa.amount_adjusted        AS e_amount_adjusted       -- �C���ώc��
            ,apsa.amount_credited        AS e_amount_credited       -- �N���W�b�g�����c��
            ,hp.status                   AS e_hp_status             -- �ڋq�p�[�e�B�X�e�[�^�X
            ,hca.status                  AS e_hca_status            -- �ڋq�A�J�E���g�X�e�[�^�X
            ,rcta.customer_trx_id        AS e_customer_trx_id       -- ���ID
    FROM     ra_customer_trx_all            rcta
            ,ra_cust_trx_types_all          rctta
            ,ar_payment_schedules_all       apsa
            ,hz_cust_accounts               hca
            ,hz_parties                     hp
-- 2020/12/01 Ver.1.2 Add Start
            ,(
              SELECT DISTINCT xil.trx_id  trx_id
              FROM   xxcfr_invoice_headers xih,
                     xxcfr_invoice_lines xil
              WHERE  xih.invoice_id      = xil.invoice_id
              AND    xih.cutoff_date     = gd_target_date           -- ����
              AND    xih.bill_cust_code  = gv_bill_cust_code        -- ������ڋq
             ) inv
-- 2020/12/01 Ver.1.2 Add End
    WHERE    1 = 1
    AND      hp.party_id            = hca.party_id
    AND      hca.cust_account_id    = rcta.bill_to_customer_id
    AND      rctta.cust_trx_type_id = rcta.cust_trx_type_id
    AND      apsa.customer_trx_id   = rcta.customer_trx_id
    AND      apsa.org_id            = rcta.org_id
    AND      rctta.org_id           = rcta.org_id
    AND NOT EXISTS (
        SELECT 1
        FROM   ar_receivable_applications_all raa
        WHERE  1 = 1
        AND    rcta.customer_trx_id = raa.applied_customer_trx_id
        AND    raa.status           = cv_raa_stat
        AND    raa.display          = cv_raa_disp
    )
    AND      hca.account_number     = gv_bill_cust_code             -- ������ڋq
    AND      rcta.org_id            = cn_org_id                     -- ���O�C�����[�U�g�D
    AND      rcta.request_id        = in_request_id                 -- �v��ID
-- 2020/12/01 Ver.1.2 Mod Start
---- 2015/01/08 Ver.1.1 Mod Start
----    AND      apsa.due_date          = gd_target_date                -- ����
--    AND EXISTS (
--        SELECT /*+ INDEX_SS(xil XXCFR_INVOICE_LINES_N01) */
--               'X'
--        FROM   xxcfr_invoice_lines xil
--        WHERE  xil.trx_id      = rcta.customer_trx_id
--        AND    xil.cutoff_date = gd_target_date                     -- ����
--    )
---- 2015/01/08 Ver.1.1 Mod End
    AND  inv.trx_id                 = rcta.customer_trx_id
-- 2020/12/01 Ver.1.2 Mod End
    AND      rcta.attribute7        = gv_status_from                -- �ύX�ΏۃX�e�[�^�X
    ORDER BY rcta.trx_date
-- 2015/01/08 Ver.1.1 Mod Start
--    FOR UPDATE NOWAIT
    FOR UPDATE OF rcta.customer_trx_id NOWAIT
-- 2015/01/08 Ver.1.1 Mod End
  ;
  target_rec target_cur%ROWTYPE;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf           OUT    VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT    VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT    VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
    --���O�o�͗p�i���s���[�h0�̂Ƃ��X�V���A1�̂Ƃ��X�V��X�e�[�^�X�j
    IF (gv_exe_mode = cv_execmode_chk) THEN
        gv_status := gv_status_from;
    ELSIF (gv_exe_mode = cv_execmode_upd) THEN
        gv_status := gv_status_to;
    END IF;
--
    --���O�w�b�_�s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => 
            '"�������ۗ��X�e�[�^�X",'           ||
            '"����ԍ�",'                       ||
            '"�����",'                         ||
            '"����^�C�v",'                     ||
            '"�������o�͑Ώۋ敪",'             ||
            '"�ŏI�X�V�v���O������",'           ||
            '"�ŏI�X�V�v��ID",'                 ||
            '"�ŏI�X�V��",'                     ||
            '"�����ڋq�ԍ�",'                   ||
            '"�����ڋq��",'                     ||
            '"�������������z",'                 ||
            '"������c��",'                     ||
            '"�����ώc��",'                     ||
            '"�C���ώc��",'                     ||
            '"�N���W�b�g�����c��",'             ||
            '"�ڋq�p�[�e�B�X�e�[�^�X",'         ||
            '"�ڋq�A�J�E���g�X�e�[�^�X"'
    );
--
    -- �v��ID���Ƃɏ���
    FOR i IN 1..gn_request_id.COUNT LOOP
--
        -- ���b�N����Ă�����G���[�ŗ��Ƃ�
        OPEN target_cur(
            in_request_id => gn_request_id(i)
        );
        --
        LOOP
            -- �Ώۃf�[�^�擾�J�[�\��
            FETCH target_cur INTO target_rec;
            --
            EXIT WHEN target_cur%NOTFOUND;
            --
            -- �������[�h���X�V
            IF (gv_exe_mode = cv_execmode_upd) THEN
                --
                UPDATE
                      ra_customer_trx_all     rcta
                SET
                      rcta.attribute7       = gv_status_to                   -- �������ۗ��X�e�[�^�X
                WHERE 1 = 1
                AND   rcta.customer_trx_id  = target_rec.e_customer_trx_id   -- ���ID(�Ώیڋq�A�Ώے����A�ΏەύX�X�e�[�^�X)
                ;
            END IF;
            --
            -- ���O�ɑΏۏ��o��
            FND_FILE.PUT_LINE(
                which  => FND_FILE.LOG
               ,buff   =>                                                         '"' ||
                    gv_status                                                || '","' || 
                    target_rec.e_trx_number                                  || '","' ||
                    TO_CHAR(target_rec.e_trx_date        , cv_date_format)   || '","' ||
                    target_rec.e_name                                        || '","' ||
                    target_rec.e_attribute1                                  || '","' ||
                    target_rec.e_conc_name                                   || '","' || 
                    target_rec.e_request_id                                  || '","' || 
                    TO_CHAR(target_rec.e_last_update_date, cv_date_format)   || '","' || 
                    target_rec.e_account_number                              || '","' || 
                    target_rec.e_party_name                                  || '","' || 
                    target_rec.e_amount_due_original                         || '","' || 
                    target_rec.e_amount_due_remaining                        || '","' || 
                    target_rec.e_amount_applied                              || '","' || 
                    target_rec.e_amount_adjusted                             || '","' || 
                    target_rec.e_amount_credited                             || '","' || 
                    target_rec.e_hp_status                                   || '","' || 
                    target_rec.e_hca_status                                  || '"' 
            ); 
            -- ���������J�E���g�A�b�v
            gn_target_cnt := gn_target_cnt + 1;
            --
        END LOOP;
        --
        -- �����ΏۃJ�[�\���N���[�Y
        CLOSE target_cur;
--
    END LOOP;
    --
    gn_normal_cnt := gn_target_cnt;
--
--###########################  �Œ蕔 END   ############################
--
--
--
  EXCEPTION
--
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf              OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode             OUT    VARCHAR2,       --   ���^�[���E�R�[�h    --# �Œ� #
    iv_exe_mode         IN     VARCHAR2,       --   ���s���[�h
    iv_bill_cust_code   IN     VARCHAR2,       --   ������ڋq
    iv_target_date      IN     VARCHAR2,       --   ����
    iv_business_date    IN     VARCHAR2,       --   �Ɩ����t
    iv_request_id       IN     VARCHAR2,       --   �v��ID
    iv_status_from      IN     VARCHAR2,       --   �X�V�ΏۃX�e�[�^�X
    iv_status_to        IN     VARCHAR2        --   �X�V��X�e�[�^�X
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
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
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
--
    -- ===============================================
    -- ��������
    -- ===============================================
    --
    -- 1.�ϐ�������
    gn_request_id.DELETE;
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- 2.�p�����[�^�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '���s���[�h�F'   || iv_exe_mode
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '������ڋq�F'   || iv_bill_cust_code
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�����F'         || TO_CHAR( TO_DATE ( iv_target_date,   cv_date_format ), cv_date_format2 )
    );
    IF (iv_business_date IS NOT NULL) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => '�Ɩ����t�F' || TO_CHAR( TO_DATE ( iv_business_date, cv_date_format ), cv_date_format2 )
        );
    ELSE
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => '�v��ID�F'   || iv_request_id
        );
    END IF;
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�X�V�ΏۃX�e�[�^�X�F' || iv_status_from
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�X�V��X�e�[�^�X�F'   || iv_status_to
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL --���s
    );
--
    -- 3.�K�{�p�����[�^�`�F�b�N
    IF (iv_business_date IS NULL AND iv_request_id IS NULL) THEN
       lv_errmsg := '�K�{�p�����[�^�����͂���Ă��܂���B'       || chr(10) || '�Ɩ����t���v��ID����͂��Ă��������B';
        -- ���^�[���R�[�h�X�V
        lv_retcode := cv_status_error;
    ELSIF (iv_business_date IS NOT NULL AND iv_request_id IS NOT NULL) THEN
       lv_errmsg := '�Ɩ����t�Ɨv��ID�̗��������͂���Ă��܂��B' || chr(10) || '�ǂ��炩����݂̂���͂��Ă��������B';
        -- ���^�[���R�[�h�X�V
        lv_retcode := cv_status_error;
    END IF;
--
    IF( lv_retcode = cv_status_normal ) THEN
      -- �p�����[�^���O���[�o���ϐ��ɐݒ�
      gv_exe_mode       := iv_exe_mode;                             -- ���s���[�h
      gv_bill_cust_code := iv_bill_cust_code;                       -- ������ڋq
      gd_target_date    := TO_DATE(iv_target_date, cv_date_format); -- ����
      --
      -- �Ɩ����t�w��̏ꍇ�͐������ׂ̍쐬������v��ID�𓱏o����
      IF (iv_business_date IS NOT NULL) THEN
         --
         gd_business_date  := TO_DATE(iv_business_date, 'RRRR/MM/DD HH24:MI:SS');
         --
         SELECT            rcta.request_id AS request_id
         BULK COLLECT INTO gn_request_id
         FROM              ra_customer_trx_all rcta
                          ,xxcfr_invoice_lines xil
         WHERE             1 = 1
         AND               rcta.customer_trx_id  = xil.trx_id
         -- �Ɩ����t ���� ��00:00���쐬����06:00
         AND               xil.creation_date    >= NVL(TRUNC(gd_business_date) + 1       , xil.creation_date)
         AND               xil.creation_date    <= NVL(TRUNC(gd_business_date) + 1 + 6/24, xil.creation_date)
         GROUP BY          rcta.request_id
         ;
         --
         -- �w�肵���Ɩ����t�ɐ������ׂ��쐬����Ă��Ȃ������ꍇ
         IF (gn_request_id.COUNT = 0) THEN
           lv_errmsg :=  '�w�肳�ꂽ�Ɩ����t�ɑ΂���1�����v��ID�����o����܂���ł����B';
           -- ���^�[���R�[�h�X�V
           lv_retcode := cv_status_error;
         END IF;
      -- �v��ID
      ELSE
          gn_request_id(1) := TO_NUMBER(iv_request_id);
      END IF;
--
    END IF;
--
    IF( lv_retcode = cv_status_normal ) THEN
      -- �ύX�ΏۃX�e�[�^�X
      gv_status_from := iv_status_from;
      -- �ύX��X�e�[�^�X
      gv_status_to   := iv_status_to;
--
      -- ===============================================
      -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
      -- ===============================================
      submain(
         lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    --
    END IF;
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      --�Ώی����N���A
      gn_target_cnt := 0;
      --���������N���A
      gn_normal_cnt := 0;
      --�X�L�b�v�����N���A
      gn_warn_cnt   := 0;
      --�G���[����
      gn_error_cnt  := 1;
    END IF;
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
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
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_normal_msg
                     );
    ELSIF(lv_retcode = cv_status_warn) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_warn_msg
                     );
    ELSIF(lv_retcode = cv_status_error) THEN
      gv_out_msg := '�������G���[�I�����܂����B';
    END IF;
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
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
END XXCCP009A03C;
/
