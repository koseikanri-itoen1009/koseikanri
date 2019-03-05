CREATE OR REPLACE PACKAGE BODY XXCSM002A19C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2019. All rights reserved.
 *
 * Package Name     : XXCSM002A19C(body)
 * Description      : �N�ԏ��i�v��_�E�����[�h
 * MD.050           : �N�ԏ��i�v��_�E�����[�h MD050_CSM_002_A19
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  location_group_csv     ���_�ʏ��i�Q�ʏ��i�v��CSV�o�� (A-2)
 *  item_csv               �P�i�ʏ��i�v��CSV�o�� (A-3)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2019/02/08    1.0   Y.Sasaki         �V�K�쐬
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
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  no_data           EXCEPTION;     -- ���i�v�斢�擾�x��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name             CONSTANT VARCHAR2(100)  :=  'XXCSM002A19C';       -- �p�b�P�[�W��
  cv_xxcsm                CONSTANT VARCHAR2(10)   :=  'XXCSM';              -- �A�v���P�[�V�����Z�k��
  -- ���b�Z�[�W�R�[�h
  cv_msg_csm1_10401       CONSTANT VARCHAR2(30)   :=  'APP-XXCSM1-10401';   -- ���̓p�����[�^�\�����b�Z�[�W
  cv_msg_csm1_10402       CONSTANT VARCHAR2(30)   :=  'APP-XXCSM1-10402';   -- ���i�v�斢�擾�x��
  -- �g�[�N��
  cv_tkn_output_kbn       CONSTANT VARCHAR2(100)  :=  'OUTPUT_KBN';
  cv_tkn_location_cd      CONSTANT VARCHAR2(100)  :=  'LOCATION_CD';
  cv_tkn_plan_year        CONSTANT VARCHAR2(100)  :=  'PLAN_YEAR';
  cv_tkn_item_group_3     CONSTANT VARCHAR2(100)  :=  'ITEM_GROUP_3';
  cv_tkn_output_data      CONSTANT VARCHAR2(100)  :=  'OUTPUT_DATA';
  -- �o�͋敪
  cv_item_sales_plan      CONSTANT VARCHAR2(2)    :=  '01';                 -- �o�͋敪:�P�i��
  -- ���i�敪
  cv_item_kbn_0           CONSTANT VARCHAR2(1)    :=  '0';                  -- ���i�敪:���i�Q
  cv_item_kbn_1           CONSTANT VARCHAR2(1)    :=  '1';                  -- ���i�敪:���i�P�i
  -- �o�͒l�R�[�h
  cv_out_data_01          CONSTANT VARCHAR2(2)    :=  '01';                 -- �o�͒l�F�e���z
  cv_out_data_02          CONSTANT VARCHAR2(2)    :=  '02';                 -- �o�͒l�F�e����
  cv_out_data_03          CONSTANT VARCHAR2(2)    :=  '03';                 -- �o�͒l�F�|��
  cv_out_data_99          CONSTANT VARCHAR2(2)    :=  '99';                 -- �o�͒l�F�S��
  -- �v�Z�p
  cn_1000                 CONSTANT NUMBER         :=  1000;                 -- �v�Z�p:1000
  -- �o�͕�����
  cv_comma                CONSTANT VARCHAR2(1)    :=  ',';
  cv_uriage               CONSTANT VARCHAR2(6)    :=  '����';
  cv_ararigaku            CONSTANT VARCHAR2(9)    :=  '�e���z';
  cv_arariritu            CONSTANT VARCHAR2(9)    :=  '�e����';
  cv_kakeritu             CONSTANT VARCHAR2(6)    :=  '�|��';
  cv_kyotenkei            CONSTANT VARCHAR2(9)    :=  '���_�v';
  cv_uriagenebiki         CONSTANT VARCHAR2(12)   :=  '����l��';
  cv_nyuukinnebiki        CONSTANT VARCHAR2(12)   :=  '�����l��';
  cv_uriageyosan          CONSTANT VARCHAR2(12)   :=  '����\�Z';
  cv_kyotenkodo           CONSTANT VARCHAR2(15)   :=  '���_�R�[�h';
  cv_nendo                CONSTANT VARCHAR2(15)   :=  '�N�x';
  cv_yosankubun           CONSTANT VARCHAR2(15)   :=  '�\�Z�敪';
  cv_rekodokubun          CONSTANT VARCHAR2(15)   :=  '���R�[�h�敪';
  cv_syouhingun           CONSTANT VARCHAR2(15)   :=  '���i�Q';
  cv_syouhinkodo          CONSTANT VARCHAR2(15)   :=  '���i�R�[�h';
  cv_syouhinmei           CONSTANT VARCHAR2(15)   :=  '���i��';
  cv_5gatu                CONSTANT VARCHAR2(15)   :=  '5����';
  cv_6gatu                CONSTANT VARCHAR2(15)   :=  '6����';
  cv_7gatu                CONSTANT VARCHAR2(15)   :=  '7����';
  cv_8gatu                CONSTANT VARCHAR2(15)   :=  '8����';
  cv_9gatu                CONSTANT VARCHAR2(15)   :=  '9����';
  cv_10gatu               CONSTANT VARCHAR2(15)   :=  '10����';
  cv_11gatu               CONSTANT VARCHAR2(15)   :=  '11����';
  cv_12gatu               CONSTANT VARCHAR2(15)   :=  '12����';
  cv_1gatu                CONSTANT VARCHAR2(15)   :=  '1����';
  cv_2gatu                CONSTANT VARCHAR2(15)   :=  '2����';
  cv_3gatu                CONSTANT VARCHAR2(15)   :=  '3����';
  cv_4gatu                CONSTANT VARCHAR2(15)   :=  '4����';
  cv_nenkankei            CONSTANT VARCHAR2(15)   :=  '�N�Ԍv';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- ���̓p�����[�^
  gv_output_kbn     VARCHAR2(30);     --  �o�͋敪
  gv_location_cd    VARCHAR2(30);     --  ���_
  gn_plan_year      NUMBER;           --  �N�x
  gv_item_group_3   VARCHAR2(30);     --  ���i�Q3
  gv_output_data    VARCHAR2(30);     --  �o�͒l
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      iv_output_kbn     IN  VARCHAR2      --  �o�͋敪
    , iv_location_cd    IN  VARCHAR2      --  ���_
    , iv_plan_year      IN  VARCHAR2      --  �N�x
    , iv_item_group_3   IN  VARCHAR2      --  ���i�Q3
    , iv_output_data    IN  VARCHAR2      --  �o�͒l
    , ov_errbuf         OUT VARCHAR2      --  �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode        OUT VARCHAR2      --  ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg         OUT VARCHAR2      --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
    lv_pram_out VARCHAR2(1000);  -- ���̓p�����[�^���b�Z�[�W
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
--  ************************************************
    -- ���̓p�����[�^�o��
--  ************************************************
    -- ���b�Z�[�W���擾
    lv_pram_out :=  xxccp_common_pkg.get_msg(                          --   �o�͋敪�̏o��
                        iv_application    =>  cv_xxcsm                 --   �A�v���P�[�V�����Z�k��
                      , iv_name           =>  cv_msg_csm1_10401        --   ���b�Z�[�W�R�[�h
                      , iv_token_name1    =>  cv_tkn_output_kbn        --   �g�[�N���R�[�h1�i�o�͋敪�j
                      , iv_token_value1   =>  iv_output_kbn            --   �g�[�N���l1
                      , iv_token_name2    =>  cv_tkn_location_cd       --   �g�[�N���R�[�h2�i���_�j
                      , iv_token_value2   =>  iv_location_cd           --   �g�[�N���l2
                      , iv_token_name3    =>  cv_tkn_plan_year         --   �g�[�N���R�[�h3�i�N�x�j
                      , iv_token_value3   =>  iv_plan_year             --   �g�[�N���l3
                      , iv_token_name4    =>  cv_tkn_item_group_3      --   �g�[�N���R�[�h4�i���i�Q�j
                      , iv_token_value4   =>  iv_item_group_3          --   �g�[�N���l4
                      , iv_token_name5    =>  cv_tkn_output_data       --   �g�[�N���R�[�h5�i�o�͒l�j
                      , iv_token_value5   =>  iv_output_data           --   �g�[�N���l5
                    );
    --
    -- ���O�Ƀp�����[�^���o��
    fnd_file.put_line(
        which   =>  FND_FILE.LOG
      , buff    =>  lv_pram_out
    );
    -- ���O�ɋ�s���o��
    fnd_file.put_line(
        which   =>  FND_FILE.LOG
      , buff    =>  CHR(10)
    );
    --
    -- �p�����[�^��ێ�
    gv_output_kbn       :=  iv_output_kbn;
    gv_location_cd      :=  iv_location_cd;
    gn_plan_year        :=  TO_NUMBER(iv_plan_year);
    gv_item_group_3     :=  iv_item_group_3;
    gv_output_data      :=  iv_output_data;
    --
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
   * Procedure Name   : location_group_csv
   * Description      : ���_�ʏ��i�Q�ʏ��i�v��f�[�^�o�͏���(A-2)
   ***********************************************************************************/
  PROCEDURE location_group_csv(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'location_group_csv'; -- �v���O������
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
    cv_asterisk_5   CONSTANT VARCHAR(5)  :=  '*****';-- ���_�ʂ̔N�Ԍv�p�o�͒l
    --
    -- *** ���[�J���ϐ� ***
    lv_header           VARCHAR2(1000);       --  �w�b�_�[�i�[�ϐ�
    lv_uriage           VARCHAR2(2000);       --  ����CSV�o�͍s
    lv_agm              VARCHAR2(2000);       --  �e���zCSV�o�͍s
    lv_mr               VARCHAR2(2000);       --  �e����CSV�o�͍s
    lv_cr               VARCHAR2(2000);       --  �|��CSV�o�͍s
    lv_sales_dcnt       VARCHAR2(2000);       --  ����l��CSV�o�͍s
    lv_receipt_dcnt     VARCHAR2(2000);       --  �����l��CSV�o�͍s
    lv_sales_bdg        VARCHAR2(2000);       --  ����\�ZCSV�o�͍s
    lv_item_group_no    VARCHAR2(10);         --  �O�񏤕i�Q
    ln_count            NUMBER;               --  ���[�v�J�E���^
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���_�ʏ��i�v��擾�J�[�\��
    CURSOR get_location_sales_plan_cur
    IS
      SELECT   xiph.location_cd       AS  location_cd               --  ���_�R�[�h
             , xiph.plan_year         AS  plan_year                 --  �N�x
             , xiplb.sales_budget     AS  sales_budget              --  ����\�Z
             , xiplb.receipt_discount AS  receipt_discount          --  �����l��
             , xiplb.sales_discount   AS  sales_discount            --  ����l��
      FROM     xxcsm_item_plan_loc_bdgt  xiplb
             , xxcsm_item_plan_headers   xiph
      WHERE    xiplb.item_plan_header_id    =   xiph.item_plan_header_id
      AND      xiph.plan_year               =   gn_plan_year
      AND      xiph.location_cd             =   gv_location_cd
      ORDER BY xiph.location_cd
             , xiplb.year_month
      ;
    -- ���i�Q�ʏ��i�v��擾�J�[�\��
    CURSOR get_group_sales_plan_cur
    IS
      SELECT   xiph.location_cd         AS  location_cd             --  ���_�R�[�h
             , xiph.plan_year           AS  plan_year               --  �N�x
             , xipl.item_group_no       AS  item_group_no           --  ���i�Q3
             , xipl.sales_budget        AS  sales_budget            --  ����
             , xipl.amount_gross_margin AS  amount_gross_margin     --  �e���z
             , xipl.margin_rate         AS  margin_rate             --  �e����
      FROM     xxcsm_item_plan_lines     xipl
             , xxcsm_item_plan_headers   xiph
             , xxcsm_item_group_3_nm_v   xig3nv
      WHERE    xiph.item_plan_header_id   =   xipl.item_plan_header_id
      AND      xiph.plan_year             =   gn_plan_year
      AND      xipl.item_group_no         =   xig3nv.item_group_cd
      AND      xipl.item_kbn              =   cv_item_kbn_0
      AND      xiph.location_cd           =   gv_location_cd
      AND      xipl.item_group_no         =   NVL(gv_item_group_3,xipl.item_group_no)
      ORDER BY xipl.item_group_no
             , xipl.year_month
      ;
    --
    -- ���_�ʏ��i�v��擾�J�[�\�����R�[�h�^
    get_location_sales_plan_rec     get_location_sales_plan_cur%ROWTYPE;
    -- ���_�ʏ��i�v��擾�J�[�\�����R�[�h�^
    get_group_sales_plan_rec        get_group_sales_plan_cur%ROWTYPE;
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
    --  **************************************
    --    ���_�ʏ��i�v��CSV���`
    --  **************************************
    --  �o�͏��̏�����
    ln_count         :=  0;
    lv_header        :=  gv_location_cd || cv_comma ||
                         TO_CHAR(gn_plan_year)
                     ;
    lv_sales_dcnt    :=  lv_header      || cv_comma ||
                         cv_kyotenkei   || cv_comma ||
                         cv_uriagenebiki
                     ;
    lv_receipt_dcnt  :=  lv_header      || cv_comma ||
                         cv_kyotenkei   || cv_comma ||
                         cv_nyuukinnebiki
                     ;
    lv_sales_bdg     :=  lv_header      || cv_comma ||
                         cv_kyotenkei   || cv_comma ||
                         cv_uriageyosan
                     ;
    --
    --  CSV�t�@�C���Ɍ��o�����o��
    fnd_file.put_line(
      which     =>  FND_FILE.OUTPUT
    , buff      =>  cv_kyotenkodo || cv_comma || cv_nendo || cv_comma || cv_yosankubun || cv_comma || cv_rekodokubun || cv_comma ||
                    cv_5gatu || cv_comma || cv_6gatu || cv_comma || cv_7gatu || cv_comma || cv_8gatu || cv_comma ||
                    cv_9gatu || cv_comma || cv_10gatu || cv_comma || cv_11gatu || cv_comma || cv_12gatu || cv_comma ||
                    cv_1gatu || cv_comma  || cv_2gatu || cv_comma || cv_3gatu || cv_comma || cv_4gatu ||cv_comma || cv_nenkankei
    );
    --
    <<base_loop>>
    FOR get_location_sales_plan_rec IN get_location_sales_plan_cur LOOP
      --  1�N�i12�����j���̃f�[�^���A1�s�Ɍ���
      --  �o�͗p�ϐ��ɕ����񌋍�
      --
      lv_sales_dcnt     :=  lv_sales_dcnt   || cv_comma ||
                            TO_CHAR(get_location_sales_plan_rec.sales_discount / cn_1000)
      ;
      lv_receipt_dcnt   :=  lv_receipt_dcnt || cv_comma ||
                            TO_CHAR(get_location_sales_plan_rec.receipt_discount / cn_1000)
      ;
      lv_sales_bdg      :=  lv_sales_bdg    || cv_comma ||
                            TO_CHAR(get_location_sales_plan_rec.sales_budget / cn_1000)
      ;
      ln_count  :=  ln_count + 1;
    END LOOP  base_loop;
    --
    --  **************************************
    --    ���_�ʏ��i�v��CSV�o��
    --  **************************************
    IF ( ln_count > 0 ) THEN
      --  �N�Ԍv�𕶎��񌋍�
      lv_sales_dcnt    :=  lv_sales_dcnt   || cv_comma || cv_asterisk_5 ;
      lv_receipt_dcnt  :=  lv_receipt_dcnt || cv_comma || cv_asterisk_5 ;
      lv_sales_bdg     :=  lv_sales_bdg    || cv_comma || cv_asterisk_5 ;
      --
      -- ����l��
      fnd_file.put_line(
        which     =>  FND_FILE.OUTPUT
      , buff      =>  lv_sales_dcnt
      );
      -- �����l��
      fnd_file.put_line(
          which   =>  FND_FILE.OUTPUT
        , buff    =>  lv_receipt_dcnt
      );
      -- ����\�Z
      fnd_file.put_line(
          which   =>  FND_FILE.OUTPUT
        , buff    =>  lv_sales_bdg
      );
      --  �����J�E���g
      gn_target_cnt  :=  gn_target_cnt + 1 ;
      gn_normal_cnt  :=  gn_normal_cnt + 1;
    ELSE
      --  ���_�ʗ\�Z�v���擾�ł��Ȃ������ꍇ
      gn_warn_cnt :=  gn_warn_cnt + 1;
      -- �N�ԏ��i�v��_�E�����[�h�f�[�^�Ȃ����b�Z�[�W
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_xxcsm
                        , iv_name         =>  cv_msg_csm1_10402
                      );
      lv_errbuf   :=  lv_errmsg;
      RAISE no_data;
    END IF;
    --
    --
    --  **************************************
    --    ���i�Q�ʏ��i�v��CSV���`
    --  **************************************
    --  ������
    lv_item_group_no  :=  NULL;
    lv_uriage         :=  cv_comma || cv_uriage ;
    lv_agm            :=  cv_comma || cv_ararigaku ;
    lv_mr             :=  cv_comma || cv_arariritu ;
    --
    <<group_loop>>
    FOR get_group_sales_plan_rec IN get_group_sales_plan_cur LOOP
      --
      IF ( lv_item_group_no IS NOT NULL AND get_group_sales_plan_rec.item_group_no <> lv_item_group_no ) THEN
        --  **************************************
        --    ���i�Q�ʏ��i�v��CSV�o��
        --  **************************************
        --  �Q�R�[�h���ς�����^�C�~���O�ŏo�͂����{
        --
        --  ����
        fnd_file.put_line(
            which   =>  FND_FILE.OUTPUT
          , buff    =>  lv_header || cv_comma || lv_item_group_no || lv_uriage
        );
        --  �e���z
        fnd_file.put_line(
            which   =>  FND_FILE.OUTPUT
          , buff    =>  lv_header || cv_comma || lv_item_group_no || lv_agm
        );
        --  �e����
        fnd_file.put_line(
            which   =>  FND_FILE.OUTPUT
          , buff    =>  lv_header || cv_comma || lv_item_group_no || lv_mr
        );
        --
        --  �����J�E���g
        gn_target_cnt   :=  gn_target_cnt + 1;
        gn_normal_cnt   :=  gn_normal_cnt + 1;
        -- �o�͏��̏�����
        lv_uriage   :=  cv_comma || cv_uriage ;
        lv_agm      :=  cv_comma || cv_ararigaku ;
        lv_mr       :=  cv_comma || cv_arariritu ;
      END IF;
      --
      --  1�N�i12�����j���̃f�[�^���A1�s�Ɍ���
      --  ����
      lv_uriage :=  lv_uriage || cv_comma || TO_CHAR(get_group_sales_plan_rec.sales_budget / cn_1000 ) ;
      --  �e���z�F�o�͒l���e���z(01)�܂��́A�S��(99)�̏ꍇ�擾�l��ݒ�A����ȊO�̏ꍇ�͒l��ݒ肵�Ȃ�
      lv_agm    :=  lv_agm || cv_comma ||
                    CASE 
                      WHEN gv_output_data IN( cv_out_data_01, cv_out_data_99 )
                        THEN  TO_CHAR( get_group_sales_plan_rec.amount_gross_margin / cn_1000 )
                    END
      ;
      --  �e�����F�o�͒l���e����(02)�܂��́A�S��(99)�̏ꍇ�擾�l��ݒ�A����ȊO�̏ꍇ�͒l��ݒ肵�Ȃ�
      lv_mr     :=  lv_mr || cv_comma ||
                    CASE
                      -- �o�͒l���e�����܂��͑S�Ă̏ꍇ
                      WHEN gv_output_data IN( cv_out_data_02, cv_out_data_99 )
                        THEN  TO_CHAR( get_group_sales_plan_rec.margin_rate )
                    END
      ;
      --
      --  ���i�Q�R�[�h��ێ�
      lv_item_group_no  :=  get_group_sales_plan_rec.item_group_no;
    END LOOP  group_loop;
    --
    --
    IF ( lv_item_group_no IS NOT NULL ) THEN
      --  �f�[�^�����݂���ꍇ�́A�Ō�̏��i�Q�R�[�h���̃f�[�^���o��
      --  ����
      fnd_file.put_line(
          which   =>  FND_FILE.OUTPUT
        , buff    =>  lv_header || cv_comma || lv_item_group_no || lv_uriage
      );
      --  �e���z
      fnd_file.put_line(
          which   =>  FND_FILE.OUTPUT
        , buff    =>  lv_header || cv_comma || lv_item_group_no || lv_agm
      );
      --  �e����
      fnd_file.put_line(
          which   =>  FND_FILE.OUTPUT
        , buff    =>  lv_header || cv_comma || lv_item_group_no || lv_mr
      );
      --  �����J�E���g
      gn_target_cnt  :=  gn_target_cnt + 1;
      gn_normal_cnt  :=  gn_normal_cnt + 1;
    ELSE
      --  �f�[�^���擾����Ȃ������ꍇ�A�x���I������
      gn_warn_cnt    :=  gn_warn_cnt   + 1;
      -- �N�ԏ��i�v��_�E�����[�h�f�[�^�Ȃ����b�Z�[�W
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_xxcsm
                      , iv_name           =>  cv_msg_csm1_10402
                    );
      lv_errbuf :=  lv_errmsg ;
      RAISE no_data;
    END IF;
    --
  EXCEPTION
    -- *** �N�ԏ��i�v��_�E�����[�h�f�[�^�Ȃ����b�Z�[�W ***
    WHEN no_data THEN
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;                                             --# �C�� #
--
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
      -- ================================================
      -- �J�[�\���̃N���[�Y
      -- ================================================
      IF (get_location_sales_plan_cur%ISOPEN) THEN
        CLOSE get_location_sales_plan_cur;
      END IF;
      IF (get_group_sales_plan_cur%ISOPEN) THEN
        CLOSE get_group_sales_plan_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END location_group_csv;
--
  /**********************************************************************************
   * Procedure Name   : item_csv
   * Description      : �P�i�ʏ��i�v��f�[�^�o�͏���(A-3)
   ***********************************************************************************/
  PROCEDURE item_csv(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'item_csv'; -- �v���O������
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
    lv_header  VARCHAR2(1000); -- �w�b�_�[�i�[�ϐ�
    lv_uriage  VARCHAR2(2000); -- ����CSV�o�͍s
    lv_agm     VARCHAR2(2000); -- �e���zCSV�o�͍s
    lv_mr      VARCHAR2(2000); -- �e����CSV�o�͍s
    lv_cr      VARCHAR2(2000); -- �|��CSV�o�͍s
    lv_item_no VARCHAR2(20);   -- �O��i�ڃR�[�h
    ln_count   NUMBER;         -- ���[�v�J�E���^
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �i�ڕʏ��i�v��擾�J�[�\��
    CURSOR get_item_sales_plan_cur
    IS
      SELECT   xiph.location_cd         AS location_cd         -- ���_�R�[�h
             , xiph.plan_year           AS plan_year           -- �N�x
             , xipl.item_group_no       AS item_group_no       -- ���i�Q3
             , xipl.item_no             AS item_no             -- ���i�R�[�h
             , xcgv.item_nm             AS item_nm             -- ���i��
             , xipl.sales_budget        AS sales_budget        -- ����
             , xipl.amount_gross_margin AS amount_gross_margin -- �e���z
             , xipl.margin_rate         AS margin_rate         -- �e����
             , xipl.credit_rate         AS credit_rate         -- �|��
      FROM     xxcsm_item_plan_lines     xipl
             , xxcsm_commodity_group3_v  xcgv
             , xxcsm_item_plan_headers   xiph
      WHERE    xiph.location_cd         = gv_location_cd
      AND      xiph.plan_year           = gn_plan_year
      AND      xiph.item_plan_header_id = xipl.item_plan_header_id
      AND      xipl.item_group_no       = NVL( gv_item_group_3 , xipl.item_group_no )
      AND      xipl.item_kbn            = cv_item_kbn_1
      AND      xipl.item_no             = xcgv.item_cd
      ORDER BY xipl.item_group_no
             , xipl.item_no
             , xipl.year_month
      ;
    --
    -- �i�ڕʏ��i�v��擾�J�[�\�����R�[�h�^
    get_item_sales_plan_rec get_item_sales_plan_cur%ROWTYPE;

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
    --  **************************************
    --    �i�ڕʏ��i�v��CSV���`
    --  **************************************
    --
    --�o�͏��̏�����
    lv_header  :=  NULL;
    lv_item_no :=  NULL;
    lv_uriage  :=  cv_uriage ;
    lv_agm     :=  cv_ararigaku ;
    lv_mr      :=  cv_arariritu ;
    lv_cr      :=  cv_kakeritu ;
    --
    --  CSV�t�@�C���Ɍ��o�����o��
    fnd_file.put_line(
      which     =>  FND_FILE.OUTPUT
    , buff      =>  cv_kyotenkodo || cv_comma || cv_nendo || cv_comma || cv_syouhingun || cv_comma ||
                    cv_syouhinkodo || cv_comma || cv_syouhinmei || cv_comma || cv_rekodokubun || cv_comma ||
                    cv_5gatu || cv_comma || cv_6gatu || cv_comma || cv_7gatu || cv_comma || cv_8gatu || cv_comma ||
                    cv_9gatu || cv_comma || cv_10gatu || cv_comma || cv_11gatu || cv_comma || cv_12gatu || cv_comma ||
                    cv_1gatu || cv_comma  || cv_2gatu || cv_comma || cv_3gatu || cv_comma || cv_4gatu
    );
    --
    <<item_loop>>
    FOR get_item_sales_plan_rec IN get_item_sales_plan_cur LOOP
      --
      IF ( lv_item_no IS NOT NULL AND get_item_sales_plan_rec.item_no <> lv_item_no ) THEN
        --  **************************************
        --    �i�ڕʏ��i�v��CSV�o��
        --  **************************************
        --  �i�ڃR�[�h���ς�����^�C�~���O�ŏo�͂����{
        --
        -- ����
        fnd_file.put_line(
            which   =>  FND_FILE.OUTPUT
          , buff    =>  lv_header || lv_uriage
        );
        -- �e���z
        fnd_file.put_line(
            which   =>  FND_FILE.OUTPUT
          , buff    =>  lv_header || lv_agm
        );
        -- �e����
        fnd_file.put_line(
            which   =>  FND_FILE.OUTPUT
          , buff    =>  lv_header || lv_mr
        );
        -- �|��
        fnd_file.put_line(
            which   =>  FND_FILE.OUTPUT
          , buff    =>  lv_header || lv_cr
        );
        --  �����J�E���g
        gn_target_cnt   :=  gn_target_cnt + 1;
        gn_normal_cnt   :=  gn_normal_cnt + 1;
        --�o�͏��̏�����
        lv_uriage   :=  cv_uriage;
        lv_agm      :=  cv_ararigaku;
        lv_mr       :=  cv_arariritu;
        lv_cr       :=  cv_kakeritu;
      END IF;
      --
      --  1�N�i12�����j���̃f�[�^���A1�s�Ɍ���
      -- ����
      lv_uriage :=  lv_uriage || cv_comma || TO_CHAR(get_item_sales_plan_rec.sales_budget / cn_1000);
      -- �e���z
      --  �e���z�F�o�͒l���e���z(01)�܂��́A�S��(99)�̏ꍇ�擾�l��ݒ�A����ȊO�̏ꍇ�͒l��ݒ肵�Ȃ�
      lv_agm    :=  lv_agm || cv_comma ||
                    CASE
                      WHEN gv_output_data IN( cv_out_data_01, cv_out_data_99 )
                        THEN  TO_CHAR(get_item_sales_plan_rec.amount_gross_margin / cn_1000)
                    END
      ;
      -- �e�����F�o�͒l���e����(02)�܂��́A�S��(99)�̏ꍇ�擾�l��ݒ�A����ȊO�̏ꍇ�͒l��ݒ肵�Ȃ�
      lv_mr     :=  lv_mr || cv_comma ||
                    CASE
                      WHEN gv_output_data IN( cv_out_data_02, cv_out_data_99 )
                        THEN  TO_CHAR(get_item_sales_plan_rec.margin_rate)
                    END
      ;
      -- �|���F�o�͒l���|��(03)�܂��́A�S��(99)�̏ꍇ�擾�l��ݒ�A����ȊO�̏ꍇ�͒l��ݒ肵�Ȃ�
      lv_cr     :=  lv_cr || cv_comma ||
                    CASE
                      WHEN gv_output_data IN( cv_out_data_03, cv_out_data_99 )
                        THEN  TO_CHAR(get_item_sales_plan_rec.credit_rate)
                    END
      ;
      --
      --  �i�ڃR�[�h��ێ�
      lv_item_no  :=  get_item_sales_plan_rec.item_no;
      --  �w�b�_����ێ�
      lv_header  :=  get_item_sales_plan_rec.location_cd        || cv_comma ||
                     TO_CHAR(get_item_sales_plan_rec.plan_year) || cv_comma ||
                     get_item_sales_plan_rec.item_group_no      || cv_comma ||
                     get_item_sales_plan_rec.item_no            || cv_comma ||
                     get_item_sales_plan_rec.item_nm            || cv_comma
      ;
    END LOOP  item_loop;
    --
    --
    IF ( lv_item_no IS NOT NULL ) THEN
      --  �f�[�^�����݂���ꍇ�́A�Ō�̕i�ڃR�[�h���̃f�[�^���o��
      -- ����
      fnd_file.put_line(
                         which  => FND_FILE.OUTPUT
                        ,buff   => lv_header || lv_uriage
                        );
      -- �e���z
      fnd_file.put_line(
          which   =>  FND_FILE.OUTPUT
        , buff    =>  lv_header || lv_agm
      );
      -- �e����
      fnd_file.put_line(
          which   =>  FND_FILE.OUTPUT
        , buff    =>  lv_header || lv_mr
      );
      -- �|��
      fnd_file.put_line(
          which   =>  FND_FILE.OUTPUT
        , buff    =>  lv_header || lv_cr
      );
      --  �����J�E���g
      gn_target_cnt   :=  gn_target_cnt + 1 ;
      gn_normal_cnt   :=  gn_normal_cnt + 1;
    ELSE
      --  �f�[�^���擾����Ȃ������ꍇ�A�x���I������
      gn_warn_cnt :=  gn_warn_cnt + 1;
      --  �N�ԏ��i�v��_�E�����[�h�f�[�^�Ȃ����b�Z�[�W
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_xxcsm
                      , iv_name           =>  cv_msg_csm1_10402
                    );
      lv_errbuf :=  lv_errmsg ;
      RAISE no_data;
    END IF;
    --
  EXCEPTION
    --*** �N�ԏ��i�v��_�E�����[�h�f�[�^�Ȃ����b�Z�[�W ***
    WHEN no_data THEN
      ov_errmsg := lv_errmsg;                                                  --# �C�� #
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;                                            --# �C�� #
--
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
      -- ================================================
      -- �J�[�\���̃N���[�Y
      -- ================================================
      IF (get_item_sales_plan_cur%ISOPEN) THEN
        CLOSE get_item_sales_plan_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END item_csv;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_output_kbn    IN VARCHAR2,   -- 1.�o�͋敪
    iv_location_cd   IN VARCHAR2,   -- 2.���_
    iv_plan_year     IN VARCHAR2,   -- 3.�N�x
    iv_item_group_3  IN VARCHAR2,   -- 4.���i�Q3
    iv_output_data   IN VARCHAR2,   -- 5.�o�͒l
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
    -- *** ���[�J���ϐ� ***
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
    --  (A-1)��������
    -- ===============================
    init(
        iv_output_kbn     =>  iv_output_kbn       --  1.�o�͋敪
      , iv_location_cd    =>  iv_location_cd      --  2.���_
      , iv_plan_year      =>  iv_plan_year        --  3.�N�x
      , iv_item_group_3   =>  iv_item_group_3     --  4.���i�Q3
      , iv_output_data    =>  iv_output_data      --  5.�o�͒l
      , ov_errbuf         =>  lv_errbuf           --  �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode        =>  lv_retcode          --  ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg         =>  lv_errmsg           --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --  �I������
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
    --
    IF ( gv_output_kbn = cv_item_sales_plan )
      THEN
      -- ===============================
      --  (A-2)���_�ʏ��i�Q�ʏ��i�v��CSV�o��
      -- ===============================
      --  �o�͋敪01(���_�ʏ��i�Q��)�̏ꍇ
      location_group_csv(
          ov_errbuf   =>  lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
        , ov_retcode  =>  lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
        , ov_errmsg   =>  lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --  �I������
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    --
    ELSE
      -- ===============================
      --  (A-3)�P�i�ʏ��i�v��CSV�o��
      -- ===============================
      --  �o�͋敪02(�P�i��)�̏ꍇ
      item_csv(
          ov_errbuf   =>  lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
        , ov_retcode  =>  lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
        , ov_errmsg   =>  lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --  �I������
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
    --
    -- �߂�l�ɑ��
    ov_retcode  :=  lv_retcode;
    ov_errbuf   :=  lv_errbuf;
    ov_errmsg   :=  lv_errmsg;
--
  EXCEPTION
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
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_output_kbn     IN VARCHAR2,          -- 1.�o�͋敪
    iv_location_cd    IN VARCHAR2,          -- 2.���_
    iv_plan_year      IN VARCHAR2,          -- 3.�N�x
    iv_item_group_3   IN VARCHAR2,          -- 4.���i�Q3
    iv_output_data    IN VARCHAR2           -- 5.�o�͒l
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
    cv_which_log       CONSTANT VARCHAR2(10)  := 'LOG';              -- �o�͐�
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
       iv_which   => cv_which_log
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
        iv_output_kbn     =>  iv_output_kbn       --  1.�o�͋敪
      , iv_location_cd    =>  iv_location_cd      --  2.���_
      , iv_plan_year      =>  iv_plan_year        --  3.�N�x
      , iv_item_group_3   =>  iv_item_group_3     --  4.���i�Q3
      , iv_output_data    =>  iv_output_data      --  5.�o�͒l
      , ov_errbuf         =>  lv_errbuf           --  �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode        =>  lv_retcode          --  ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg         =>  lv_errmsg           --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
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
    END IF;
    --�x���o��
    IF (lv_retcode = cv_status_warn) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
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
    --
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
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
END XXCSM002A19C;
/
