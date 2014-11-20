create or replace PACKAGE BODY xxwip_common3_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name           : xxwip_common_pkg(BODY)
 * Description            : ���ʊ֐�(XXWIP)(BODY)
 * MD.070(CMD.050)        : �Ȃ�
 * Version                : 1.0
 *
 * Program List
 *  --------------------   ---- ----- --------------------------------------------------
 *   Name                  Type  Ret   Description
 *  --------------------   ---- ----- --------------------------------------------------
 *  check_lastmonth_close   P        �O���^������`�F�b�N
 *  get_ship_method         P        �z���敪���VIEW���o
 *  get_delivery_distance   P        �z�������A�h�I���}�X�^���o 
 *  get_delivery_company    P        �^���p�^���Ǝ҃A�h�I���}�X�^���o
 *  get_delivery_charges    P        �^���A�h�I���}�X�^���o
 *  change_code_division    P        �^���R�[�h�敪�ϊ�
 *  deliv_rcv_ship_conv_qty F   NUM  �^�����o�Ɋ��Z�֐�
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2007/11/13   1.0   H.Itou           �V�K�쐬
 *
 *****************************************************************************************/
--
--###############################  �Œ�O���[�o���萔�錾�� START   ###############################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';   --����
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';   --�x��
  gv_status_error  CONSTANT VARCHAR2(1) := '2';   --���s
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';   --�X�e�[�^�X(����)
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';   --�X�e�[�^�X(�x��)
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';   --�X�e�[�^�X(���s)
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_dot       CONSTANT VARCHAR2(3) := '.';
  gv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
  gv_flg_on        CONSTANT VARCHAR2(1) := '1';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  gv_prof_cost_price CONSTANT VARCHAR2(26) := 'XXCMN_COST_PRICE_WHSE_CODE';
--
--#####################################  �Œ蕔 END   #############################################
--
--###############################  �Œ�O���[�o���ϐ��錾�� START   ###############################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);             -- ���s���[�U��
  gv_conc_name     VARCHAR2(30);              -- ���s�R���J�����g��
  gv_conc_status   VARCHAR2(30);              -- ��������
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- ���s����
  gn_warn_cnt      NUMBER;                    -- �x������
  gn_report_cnt    NUMBER;                    -- ���|�[�g����
--
--#####################################  �Œ蕔 END   #############################################
--
--##################################  �Œ苤�ʗ�O�錾�� START   ##################################
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
--#####################################  �Œ蕔 END   #############################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  check_lock_expt        EXCEPTION;     -- ���b�N�擾�G���[
--
  PRAGMA EXCEPTION_INIT(check_lock_expt,   -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name        CONSTANT VARCHAR2(100) := 'xxwip_common3_pkg'; -- �p�b�P�[�W��
  -- ���W���[��������
  gv_xxcmn           CONSTANT VARCHAR2(100) := 'XXCMN';            -- ���W���[�������́FXXCMN ����
  gv_xxwip           CONSTANT VARCHAR2(100) := 'XXWIP';            -- ���W���[�������́FXXWIP ���Y�E�i���Ǘ��E�^���v�Z
  -- ���b�Z�[�W
  gv_xxcom_nodata_err   CONSTANT VARCHAR2(15) := 'APP-XXCMN-10001';  -- �Ώۃf�[�^���擾�G���[
  gv_xxcom_noprof_err   CONSTANT VARCHAR2(15) := 'APP-XXCMN-10002';  -- �v���t�@�C���擾�G���[
  gv_xxcom_para_err     CONSTANT VARCHAR2(15) := 'APP-XXCMN-10010';  -- �p�����[�^�G���[
  -- �g�[�N��
  gv_tkn_table        CONSTANT VARCHAR2(100) := 'TABLE';
  gv_tkn_key          CONSTANT VARCHAR2(100) := 'KEY';
  gv_tkn_ng_profile   CONSTANT VARCHAR2(100) := 'NG_PROFILE';
  gv_tkn_para         CONSTANT VARCHAR2(100) := 'PARAMETER';
  gv_tkn_value        CONSTANT VARCHAR2(100) := 'VALUE';
--
  -- �v���t�@�C��
  gv_prf_grace_period   CONSTANT VARCHAR2(50) := 'XXWIP_GRACE_PERIOD';  -- �v���t�@�C���F�^���v�Z�p�P�\����
--
  -- �^�C�v
  gv_type_y           CONSTANT VARCHAR2(1)   := 'Y';                -- �^�C�v�FY
  gv_type_n           CONSTANT VARCHAR2(1)   := 'N';                -- �^�C�v�FN
--
  -- ����
  gv_acct_periods     CONSTANT VARCHAR2(100) := '�݌ɉ�v����';
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
   * Function Name    : check_lastmonth_close
   * Description      : �O���^������`�F�b�N
   ***********************************************************************************/
  PROCEDURE check_lastmonth_close(
    ov_close_type   OUT NOCOPY VARCHAR2,    -- ���ߋ敪�iY�F���ߑO�AN�F���ߌ�j
    ov_errbuf       OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_lastmonth_close' ; --�v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf     VARCHAR2(5000);   -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_open_flag            org_acct_periods.open_flag%TYPE;          -- �I�[�v���t���O
    ld_period_close_date    org_acct_periods.period_close_date%TYPE;  -- �N���[�Y���t
    lv_orgn_code            sy_orgn_mst.orgn_code%TYPE;               -- �g�D
    ln_grace_period         NUMBER;                                   -- �^���v�Z�p�P�\����
    ld_temp_date            DATE;                                     -- �N���[�Y���t+�P�\����
--
  BEGIN
    -- ***********************************************
    -- �v���t�@�C���F�����q�� �擾
    -- ***********************************************
    lv_orgn_code := FND_PROFILE.VALUE(gv_prof_cost_price);
    IF (lv_orgn_code IS NULL) THEN -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_noprof_err,
                                            gv_tkn_ng_profile,
                                            gv_prof_cost_price);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ***********************************************
    -- �v���t�@�C���F�^���v�Z�p�P�\���� �擾
    -- ***********************************************
    ln_grace_period := FND_PROFILE.VALUE(gv_prf_grace_period);
    IF (ln_grace_period IS NULL) THEN -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_noprof_err,
                                            gv_tkn_ng_profile,
                                            gv_prf_grace_period);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ***********************************************
    --  �݌ɉ�v���� ���
    --    �I�[�v���t���O�A�N���[�Y���擾
    -- ***********************************************
    BEGIN
      SELECT  oap.open_flag            -- �I�[�v���t���O
             ,oap.period_close_date    -- �N���[�Y���t
      INTO    lv_open_flag
             ,ld_period_close_date
      FROM    org_acct_periods        oap -- �݌ɉ�v����
             ,ic_whse_mst             iwm -- OPM�q�Ƀ}�X�^
      WHERE   oap.period_start_date  =
              TO_DATE(TO_CHAR(ADD_MONTHS(SYSDATE, -1), 'YYYYMM') || '01', 'YYYYMMDD')  -- �O���̏���
      AND     oap.organization_id   = iwm.mtl_organization_id                          -- �݌ɑg�DID
      AND     iwm.whse_code = lv_orgn_code;                                            -- �q�ɃR�[�h
    EXCEPTION
      WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN                       --*** �f�[�^�擾�G���[ ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                              gv_xxcom_nodata_err,
                                              gv_tkn_table,
                                              gv_acct_periods,
                                              gv_tkn_key,
                                              lv_orgn_code);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- ***********************************************
    -- ���ߓ�����
    -- ***********************************************
    -- OPEN_FLAG���uY�v�̏ꍇ
    IF (lv_open_flag = gv_type_y) THEN
      -- �O���J�����_�[��OPEN�Ȃ̂�Y��Ԃ�
      ov_close_type :=  gv_type_y;
--
    -- OPEN_FLAG���uN�v�̏ꍇ
    ELSE
      -- ***********************************************
      -- �c�Ɠ��擾 �ďo
      --   �N���[�Y���t + �P�\���Ԃ̉c�Ɠ����擾
      -- ***********************************************
      xxwip_common_pkg.get_business_date(
        id_date           => ld_PERIOD_CLOSE_DATE   -- IN  �N���[�Y���t
       ,in_period         => ln_grace_period        -- IN�� �v���t�@�C���I�v�V���� �P�\����
       ,od_business_date  => ld_temp_date           -- OUT �N���[�Y���t+�P�\����
       ,ov_errbuf         => lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      -- �G���[�̏ꍇ�A�����I��
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- �N���[�Y���t + �P�\���Ԃ�SYSDATE�����̏ꍇ
      IF (ld_temp_date <= SYSDATE) THEN
        -- OPEN�Ȃ̂�Y��Ԃ�
        ov_close_type := gv_type_y;
--
      -- �N���[�Y���t+�P�\���Ԃ�SYSDATE��薢���̏ꍇ
      ELSE
        -- CLOSE�Ȃ̂�N��Ԃ�
        ov_close_type := gv_type_n;
      END IF;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--###################################  �Œ蕔 END   #########################################
--
  END check_lastmonth_close;
--
  /**********************************************************************************
   * Function Name    : get_ship_method
   * Description      : �z���敪���VIEW���o
   ***********************************************************************************/
  PROCEDURE get_ship_method(
    iv_ship_method_code IN  xxwsh_ship_method2_v.ship_method_code%TYPE,           -- �z���敪
    id_target_date      IN  DATE,                                                 -- ���f��
    or_dlvry_dstn       OUT ship_method_rec,                                      -- �z���敪���R�[�h
    ov_errbuf           OUT NOCOPY  VARCHAR2,    -- �G���[�E���b�Z�[�W            --# �Œ� #
    ov_retcode          OUT NOCOPY  VARCHAR2,    -- ���^�[���E�R�[�h              --# �Œ� #
    ov_errmsg           OUT NOCOPY  VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ship_method' ; --�v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf     VARCHAR2(5000);   -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***********************************************
    -- ���̓p�����[�^�`�F�b�N
    -- ***********************************************
    -- �u�z���敪�v�`�F�b�N
    IF (iv_ship_method_code IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            'ship_method_code',
                                            gv_tkn_value,
                                            iv_ship_method_code);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �u������v�`�F�b�N
    IF (id_target_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            'target_date',
                                            gv_tkn_value,
                                            id_target_date);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- **************************************************
    -- *** �z���敪���擾
    -- **************************************************
    BEGIN
      SELECT  small_amount_class
            , mixed_class
      INTO    or_dlvry_dstn.small_amount_class    -- �����敪
            , or_dlvry_dstn.mixed_class           -- ���ڋ敪
      FROM    xxwsh_ship_method2_v
      WHERE   ship_method_code    = iv_ship_method_code     -- �z���敪
      AND     start_date_active  <= TRUNC(id_target_date)   -- �L���J�n��
      AND     (                                             -- �L���I����
                (end_date_active >= TRUNC(id_target_date)) 
                OR
                (end_date_active IS NULL)
              );
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- ���݂Ȃ���ݒ�
        or_dlvry_dstn.small_amount_class := 0;    -- �����敪
        or_dlvry_dstn.mixed_class := 0;           -- ���ڋ敪
--
      WHEN TOO_MANY_ROWS THEN
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--###################################  �Œ蕔 END   #########################################
--
  END get_ship_method;
--
  /**********************************************************************************
   * Function Name    : get_delivery_distance
   * Description      : �z�������A�h�I���}�X�^���o
   ***********************************************************************************/
  PROCEDURE get_delivery_distance(
    iv_goods_classe           IN  xxwip_delivery_distance.goods_classe%TYPE,          -- ���i�敪
    iv_delivery_company_code  IN  xxwip_delivery_distance.delivery_company_code%TYPE, -- �^���Ǝ�
    iv_origin_shipment        IN  xxwip_delivery_distance.origin_shipment%TYPE,       -- �o�ɑq��
    iv_code_division          IN  xxwip_delivery_distance.code_division%TYPE,         -- �R�[�h�敪
    iv_shipping_address_code  IN  xxwip_delivery_distance.shipping_address_code%TYPE, -- �z����R�[�h
    id_target_date            IN  DATE,                                               -- ���f��
    or_delivery_distance      OUT delivery_distance_rec,                              -- �z���������R�[�h
    ov_errbuf                 OUT NOCOPY  VARCHAR2,    -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode                OUT NOCOPY  VARCHAR2,    -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg                 OUT NOCOPY  VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_delivery_distance' ; --�v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf     VARCHAR2(5000);   -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***********************************************
    -- ���̓p�����[�^�`�F�b�N
    -- ***********************************************
    -- �u���i�敪�v�`�F�b�N
    IF (iv_goods_classe IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            'goods_classe',
                                            gv_tkn_value,
                                            iv_goods_classe);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �u�^���Ǝҁv�`�F�b�N
    IF (iv_delivery_company_code IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            'delivery_company_code',
                                            gv_tkn_value,
                                            iv_delivery_company_code);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �u�o�ɑq�Ɂv�`�F�b�N
    IF (iv_origin_shipment IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            'origin_shipment',
                                            gv_tkn_value,
                                            iv_origin_shipment);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �u�R�[�h�敪�v�`�F�b�N
    IF (iv_code_division IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            'code_division',
                                            gv_tkn_value,
                                            iv_code_division);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �u�z����R�[�h�v�`�F�b�N
    IF (iv_shipping_address_code IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            'shipping_address_code',
                                            gv_tkn_value,
                                            iv_shipping_address_code);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �u������v�`�F�b�N
    IF (id_target_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            'target_date',
                                            gv_tkn_value,
                                            id_target_date);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- **************************************************
    -- *** �z�������A�h�I���}�X�^���o
    -- **************************************************
    BEGIN
      SELECT  post_distance
            , small_distance
            , consolid_add_distance
            , actual_distance
      INTO    or_delivery_distance.post_distance            -- �ԗ�����
            , or_delivery_distance.small_distance           -- ��������
            , or_delivery_distance.consolid_add_distance    -- ���ڊ�������
            , or_delivery_distance.actual_distance          -- ���ۋ���
      FROM    xxwip_delivery_distance
      WHERE   goods_classe           = iv_goods_classe           -- ���i�敪
      AND     delivery_company_code  = iv_delivery_company_code  -- �^���Ǝ�
      AND     origin_shipment        = iv_origin_shipment        -- �o�ɑq��
      AND     code_division          = iv_code_division          -- �R�[�h�敪
      AND     shipping_address_code  = iv_shipping_address_code  -- �z����R�[�h
      AND     start_date_active     <= TRUNC(id_target_date)     -- �K�p�J�n��
      AND     end_date_active       >= TRUNC(id_target_date);    -- �K�p�I����
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- ���݂Ȃ���ݒ�
        or_delivery_distance.post_distance          := 0; -- �ԗ�����
        or_delivery_distance.small_distance         := 0; -- ��������
        or_delivery_distance.consolid_add_distance  := 0; -- ���ڊ�������
        or_delivery_distance.actual_distance        := 0; -- ���ۋ���
--
      WHEN TOO_MANY_ROWS THEN
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--###################################  �Œ蕔 END   #########################################
--
  END get_delivery_distance;
--
  /**********************************************************************************
   * Function Name    : get_delivery_company
   * Description      : �^���p�^���Ǝ҃A�h�I���}�X�^���o
   ***********************************************************************************/
  PROCEDURE get_delivery_company(
    iv_goods_classe           IN  xxwip_delivery_company.goods_classe%TYPE,           -- ���i�敪
    iv_delivery_company_code  IN  xxwip_delivery_company.delivery_company_code%TYPE,  -- �^���Ǝ�
    id_target_date            IN  DATE,                                               -- ���f��
    or_delivery_company       OUT delivery_company_rec,                               -- �^���p�^���Ǝ҃��R�[�h
    ov_errbuf                 OUT NOCOPY  VARCHAR2,    -- �G���[�E���b�Z�[�W          --# �Œ� #
    ov_retcode                OUT NOCOPY  VARCHAR2,    -- ���^�[���E�R�[�h            --# �Œ� #
    ov_errmsg                 OUT NOCOPY  VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W--# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_delivery_company' ; --�v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf     VARCHAR2(5000);   -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***********************************************
    -- ���̓p�����[�^�`�F�b�N
    -- ***********************************************
    -- �u���i�敪�v�`�F�b�N
    IF (iv_goods_classe IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            'goods_classe',
                                            gv_tkn_value,
                                            iv_goods_classe);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �u�^���Ǝҁv�`�F�b�N
    IF (iv_delivery_company_code IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            'delivery_company_code',
                                            gv_tkn_value,
                                            iv_delivery_company_code);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �u������v�`�F�b�N
    IF (id_target_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            'target_date',
                                            gv_tkn_value,
                                            id_target_date);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- **************************************************
    -- *** �^���p�^���Ǝ҃A�h�I���}�X�^���o
    -- **************************************************
    BEGIN
      SELECT  small_weight
            , pay_picking_amount
            , bill_picking_amount
      INTO    or_delivery_company.small_weight          -- �����d��
            , or_delivery_company.pay_picking_amount    -- �x���s�b�L���O�P��
            , or_delivery_company.bill_picking_amount   -- �����s�b�L���O�P��
      FROM    xxwip_delivery_company
      WHERE   goods_classe           = iv_goods_classe           -- ���i�敪
      AND     delivery_company_code  = iv_delivery_company_code  -- �^���Ǝ�
      AND     start_date_active     <= TRUNC(id_target_date)     -- �K�p�J�n��
      AND     end_date_active       >= TRUNC(id_target_date);    -- �K�p�I����
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- ���݂Ȃ���ݒ�
        or_delivery_company.small_weight        := 0;  -- �����d��
        or_delivery_company.pay_picking_amount  := 0;  -- �x���s�b�L���O�P��
        or_delivery_company.bill_picking_amount := 0;  -- �����s�b�L���O�P��
--
      WHEN TOO_MANY_ROWS THEN
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--###################################  �Œ蕔 END   #########################################
--
  END get_delivery_company;
--
  /**********************************************************************************
   * Function Name    : get_delivery_charges
   * Description      : �^���A�h�I���}�X�^���o
   ***********************************************************************************/
  PROCEDURE get_delivery_charges(
    iv_p_b_classe               IN  xxwip_delivery_charges.p_b_classe%TYPE,             -- �x�������敪
    iv_goods_classe             IN  xxwip_delivery_charges.goods_classe%TYPE,           -- ���i�敪
    iv_delivery_company_code    IN  xxwip_delivery_charges.delivery_company_code%TYPE,  -- �^���Ǝ�
    iv_shipping_address_classe  IN  xxwip_delivery_charges.shipping_address_classe%TYPE,-- �z���敪
    iv_delivery_distance        IN  xxwip_delivery_charges.delivery_distance%TYPE,      -- �^������
    iv_delivery_weight          IN  xxwip_delivery_charges.delivery_weight%TYPE,        -- �d��
    id_target_date              IN  DATE,                                               -- ���f��
    or_delivery_charges         OUT delivery_charges_rec,                               -- �^���A�h�I�����R�[�h
    ov_errbuf                   OUT NOCOPY  VARCHAR2,    -- �G���[�E���b�Z�[�W          --# �Œ� #
    ov_retcode                  OUT NOCOPY  VARCHAR2,    -- ���^�[���E�R�[�h            --# �Œ� #
    ov_errmsg                   OUT NOCOPY  VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W--# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_delivery_charges' ; --�v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf     VARCHAR2(5000);   -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***********************************************
    -- ���̓p�����[�^�`�F�b�N
    -- ***********************************************
    -- �u�x�������敪�v�`�F�b�N
    IF (iv_p_b_classe IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            '_p_b_classe',
                                            gv_tkn_value,
                                            iv_p_b_classe);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �u���i�敪�v�`�F�b�N
    IF (iv_goods_classe IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            'goods_classe',
                                            gv_tkn_value,
                                            iv_goods_classe);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �u�^���Ǝҁv�`�F�b�N
    IF (iv_delivery_company_code IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            'delivery_company_code',
                                            gv_tkn_value,
                                            iv_delivery_company_code);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �u�z���敪�v�`�F�b�N
    IF (iv_shipping_address_classe IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            'shipping_address_classe',
                                            gv_tkn_value,
                                            iv_shipping_address_classe);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �u�^�������v�`�F�b�N
    IF (iv_delivery_distance IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            'delivery_distance',
                                            gv_tkn_value,
                                            iv_delivery_distance);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �u�d�ʁv�`�F�b�N
    IF (iv_delivery_weight IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            'delivery_weight',
                                            gv_tkn_value,
                                            iv_delivery_weight);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �u������v�`�F�b�N
    IF (id_target_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            'target_date',
                                            gv_tkn_value,
                                            id_target_date);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- **************************************************
    -- *** �^���A�h�I���}�X�^���o �^����
    -- **************************************************
    BEGIN
      SELECT xdc.shipping_expenses
      INTO   or_delivery_charges.shipping_expenses                         -- �^����
      FROM  (SELECT  shipping_expenses
             FROM    xxwip_delivery_charges
             WHERE   p_b_classe              = iv_p_b_classe               -- �x�������敪
             AND     goods_classe            = iv_goods_classe             -- ���i�敪
             AND     delivery_company_code   = iv_delivery_company_code    -- �^���Ǝ�
             AND     shipping_address_classe = iv_shipping_address_classe  -- �z���敪
             AND     delivery_distance      >= iv_delivery_distance        -- �^������
             AND     delivery_weight        >= iv_delivery_weight          -- �d��
             AND     start_date_active      <= TRUNC(id_target_date)       -- �K�p�J�n��
             AND     end_date_active        >= TRUNC(id_target_date)       -- �K�p�I����
             ORDER BY delivery_distance ASC, delivery_weight ASC) xdc
      WHERE  ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- ���݂Ȃ���ݒ�
        or_delivery_charges.shipping_expenses := 0;   -- �^����
--
      WHEN TOO_MANY_ROWS THEN
        RAISE global_api_expt;
    END;
--
    -- **************************************************
    -- *** �^���A�h�I���}�X�^���o ���[�t���ڊ���
    -- **************************************************
    BEGIN
      SELECT  leaf_consolid_add
      INTO    or_delivery_charges.leaf_consolid_add                 -- ���[�t���ڊ���
      FROM    xxwip_delivery_charges
      WHERE   p_b_classe              = iv_p_b_classe               -- �x�������敪
      AND     goods_classe            = iv_goods_classe             -- ���i�敪
      AND     delivery_company_code   = iv_delivery_company_code    -- �^���Ǝ�
      AND     shipping_address_classe = iv_shipping_address_classe  -- �z���敪
      AND     delivery_distance       = 0                           -- �^�������i0�Œ�j
      AND     delivery_weight         = 0                           -- �d�ʁi0�Œ�j
      AND     start_date_active      <= TRUNC(id_target_date)       -- �K�p�J�n��
      AND     end_date_active        >= TRUNC(id_target_date);      -- �K�p�I����
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- ���݂Ȃ���ݒ�
        or_delivery_charges.leaf_consolid_add := 0;   -- ���[�t���ڊ���
--
      WHEN TOO_MANY_ROWS THEN
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--###################################  �Œ蕔 END   #########################################
--
  END get_delivery_charges;
--
  /**********************************************************************************
   * Function Name    : change_code_division
   * Description      : �^���R�[�h�敪�ϊ�
   ***********************************************************************************/
  PROCEDURE change_code_division(
    iv_deliver_to_code_class  IN  xxwsh_carriers_schedule.deliver_to_code_class%TYPE, -- �z����R�[�h�敪
    od_code_division          OUT xxwip_delivery_distance.code_division%TYPE,         -- �R�[�h�敪�i�^���p�j
    ov_errbuf                 OUT NOCOPY  VARCHAR2,    -- �G���[�E���b�Z�[�W          --# �Œ� #
    ov_retcode                OUT NOCOPY  VARCHAR2,    -- ���^�[���E�R�[�h            --# �Œ� #
    ov_errmsg                 OUT NOCOPY  VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W--# �Œ� #
--
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'change_code_division' ; --�v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf     VARCHAR2(5000);   -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- **************************************************
    -- *** �z����R�[�h�敪 ���� �R�[�h�敪�֕ϊ�
    -- **************************************************
    -- �S�F�q�ɂ̏ꍇ
    IF (iv_deliver_to_code_class = '4') THEN
      od_code_division := '1'; -- �q��
--
    -- �P�P�F�x����̏ꍇ
    ELSIF (iv_deliver_to_code_class = '11') THEN
      od_code_division := '2'; -- �����
--
    -- �P�F���_�A�X�F�z���̏ꍇ
    ELSIF (iv_deliver_to_code_class = '1') OR (iv_deliver_to_code_class = '9') THEN
      od_code_division := '3'; -- �z����
--
    -- ��L�ȊO�̏ꍇ
    ELSE
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            'deliver_to_code_class',
                                            gv_tkn_value,
                                            iv_deliver_to_code_class);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--###################################  �Œ蕔 END   #########################################
--
  END change_code_division;
--
  /**********************************************************************************
   * Function Name    : deliv_rcv_ship_conv_qty
   * Description      : �^�����o�Ɋ��Z�֐�
   ***********************************************************************************/
  FUNCTION deliv_rcv_ship_conv_qty(
    in_item_cd    IN VARCHAR2,          -- �i�ڃR�[�h
    in_qty        IN NUMBER)            -- �ϊ��Ώۂ̐���
    RETURN NUMBER                       -- �ϊ����ʂ̐���
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'deliv_rcv_ship_conv_qty'; --�v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
    lv_errmsg         VARCHAR2(5000); -- �G���[���b�Z�[�W
--
    ln_num_of_cases   NUMBER;       -- �P�[�X���萔
    lv_conv_unit      VARCHAR2(50); -- ���o�Ɋ��Z�P��
    ln_num_of_deliver NUMBER;       -- �o�ד���
--
    ln_converted_num  NUMBER; -- ���Z����
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    invalid_conv_unit_expt           EXCEPTION;     -- �s���Ȋ��Z�W���G���[
--
  BEGIN
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
    ln_num_of_cases   := NULL;
    lv_conv_unit      := NULL;
    ln_num_of_deliver := NULL;
--
    ln_converted_num := NULL;
--
    -- �i�ڂɂЂ��Â����Z�W�����擾����B
    SELECT  TO_NUMBER(num_of_cases)       -- �P�[�X���萔
          , conv_unit                     -- ���o�Ɋ��Z�P��
          , TO_NUMBER(num_of_deliver)  -- �o�ד���
    INTO    ln_num_of_cases
          , lv_conv_unit
          , ln_num_of_deliver
    FROM    xxcmn_item_mst_v ximv
    WHERE   ximv.item_no = in_item_cd;
--
    -- **************************************************
    -- �o�ד������ݒ肳��Ă���ꍇ
    -- **************************************************
    IF (ln_num_of_deliver IS NOT NULL ) THEN
      -- �o�ד��� �~ �ϊ��Ώۂ̐���
      ln_converted_num := CEIL(in_qty / ln_num_of_deliver);
--
    -- **************************************************
    -- ���o�Ɋ��Z�P�ʂ��ݒ肳��Ă���ꍇ
    -- **************************************************
    ELSIF (lv_conv_unit IS NOT NULL ) THEN
      -- ���o�Ɋ��Z�P�� ���擾�ł��Ȃ��ꍇ
      IF (ln_num_of_cases IS NULL) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10133',
                                              'NUM_OF_CASES',
                                              TO_CHAR(ln_num_of_cases));
        RAISE invalid_conv_unit_expt;
      END IF;
--
      -- �ϊ��Ώۂ̐��� �� �P�[�X���萔
      ln_converted_num := CEIL(in_qty / ln_num_of_cases);
--
    -- **************************************************
    -- ��L�ȊO�̏ꍇ
    -- **************************************************
    ELSE
      -- �ϊ��Ώۂ̐��ʂ��̂܂�
      ln_converted_num := in_qty;
    END IF;
--
    RETURN ln_converted_num;
--
  EXCEPTION
    WHEN invalid_conv_unit_expt THEN
      RAISE_APPLICATION_ERROR
        (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,5000),TRUE);
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END deliv_rcv_ship_conv_qty;
--
END xxwip_common3_pkg;
/
