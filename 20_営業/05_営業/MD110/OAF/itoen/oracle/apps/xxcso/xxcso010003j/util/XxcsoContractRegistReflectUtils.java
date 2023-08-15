/*============================================================================
* �t�@�C���� : XxcsoSpDecisionPropertyUtils
* �T�v����   : ���̋@�ݒu�_����o�^ �o�^��񔽉f���[�e�B���e�B�N���X
* �o�[�W���� : 1.3
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-02-02 1.0  SCS�������l  �V�K�쐬
* 2009-05-25 1.1  SCS�������l  [ST��QT1_1136]LOVPK���ڐݒ�Ή�
* 2010-03-01 1.2  SCS�������  [E_�{�ғ�_01678]�����x���Ή�
* 2023-06-08 1.3  SCSK�Ԓn�w   [E_�{�ғ�_19179]�C���{�C�X�Ή��iBM�֘A�j
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.util;

import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoContractManagementFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoContractManagementFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoPageRenderVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoPageRenderVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.util.XxcsoContractRegistConstants;
// 2010-03-01 [E_�{�ғ�_01678] Add Start
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm1BankAccountFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm1BankAccountFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm1DestinationFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm1DestinationFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm2BankAccountFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm2BankAccountFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm2DestinationFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm2DestinationFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm3BankAccountFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm3BankAccountFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm3DestinationFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm3DestinationFullVORowImpl;
// 2010-03-01 [E_�{�ғ�_01678] Add End
// Ver.1.3 Add Start
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import oracle.apps.fnd.framework.server.OADBTransaction;
// Ver.1.3 Add End

/*******************************************************************************
 * ���̋@�ݒu�_����o�^ �o�^��񔽉f���[�e�B���e�B�N���X�B
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoContractRegistReflectUtils 
{

  /*****************************************************************************
   * ���������e���f�B
   * @param pageRndrVo  �y�[�W�����ݒ�r���[�C���X�^���X
   * @param mngVo       �_��Ǘ��e�[�u�����r���[�C���X�^���X
   *****************************************************************************
   */
  public static void reflectInstallInfo(
    XxcsoPageRenderVOImpl                pageRndrVo
   ,XxcsoContractManagementFullVOImpl    mngVo
  )
  {
    // ***********************************
    // �f�[�^�s���擾
    // ***********************************
    XxcsoPageRenderVORowImpl pageRndrVoRow
      = (XxcsoPageRenderVORowImpl) pageRndrVo.first(); 

    XxcsoContractManagementFullVORowImpl mngVoRow
      = (XxcsoContractManagementFullVORowImpl) mngVo.first();

    // ///////////////////////////////////
    // �I�[�i�[�ύX�`�F�b�N�{�b�N�X�̒l�ɂ��l�𐧌�
    // //////////////////////////////////
    // �����R�[�h
    if ( ! XxcsoContractRegistConstants.OWNER_CHANGE_FLAG_ON.equals(
            pageRndrVoRow.getOwnerChangeFlag()
         ) 
    )
    {
      mngVoRow.setInstallCode(null);
// 2009-05-25 [ST��QT1_1136] Add Start
      mngVoRow.setInstanceId(null);
// 2009-05-25 [ST��QT1_1136] Add End
    }
  }
// 2010-03-01 [E_�{�ғ�_01678] Add Start
  /*****************************************************************************
   * ���������e���f�B
   * @param bm1DestVo    ���t��e�[�u�����p�r���[�C���X�^���X
   * @param bm1BankAccVo ��s�����A�h�I���}�X�^���p�r���[�C���X�^���X
   * @param bm2DestVo    ���t��e�[�u�����p�r���[�C���X�^���X
   * @param bm2BankAccVo ��s�����A�h�I���}�X�^���p�r���[�C���X�^���X
   * @param bm3DestVo    ���t��e�[�u�����p�r���[�C���X�^���X
   * @param bm3BankAccVo ��s�����A�h�I���}�X�^���p�r���[�C���X�^���X
   *****************************************************************************
   */
  public static void reflectBankAccount(
    XxcsoBm1DestinationFullVOImpl       bm1DestVo
   ,XxcsoBm1BankAccountFullVOImpl       bm1BankAccVo
   ,XxcsoBm2DestinationFullVOImpl       bm2DestVo
   ,XxcsoBm2BankAccountFullVOImpl       bm2BankAccVo
   ,XxcsoBm3DestinationFullVOImpl       bm3DestVo
   ,XxcsoBm3BankAccountFullVOImpl       bm3BankAccVo
  )
  {
    // ***********************************
    // �f�[�^�s���擾
    // ***********************************
    XxcsoBm1DestinationFullVORowImpl bm1DestVoRow
      = (XxcsoBm1DestinationFullVORowImpl) bm1DestVo.first();

    XxcsoBm1BankAccountFullVORowImpl bm1BankAccVoRow
      = (XxcsoBm1BankAccountFullVORowImpl) bm1BankAccVo.first();

    XxcsoBm2DestinationFullVORowImpl bm2DestVoRow
      = (XxcsoBm2DestinationFullVORowImpl) bm2DestVo.first();

    XxcsoBm2BankAccountFullVORowImpl bm2BankAccVoRow
      = (XxcsoBm2BankAccountFullVORowImpl) bm2BankAccVo.first();

    XxcsoBm3DestinationFullVORowImpl bm3DestVoRow
      = (XxcsoBm3DestinationFullVORowImpl) bm3DestVo.first();

    XxcsoBm3BankAccountFullVORowImpl bm3BankAccVoRow
      = (XxcsoBm3BankAccountFullVORowImpl) bm3BankAccVo.first();

    // BM�P�C�Q�C�R�̎x�����@�������x���̏ꍇ�A��������������
    if ( bm1DestVoRow != null )
    {
      if ( XxcsoContractRegistConstants.BM_PAYMENT_TYPE4.equals(bm1DestVoRow.getBellingDetailsDiv()))
      {
        // �U���萔�����S
        if (bm1DestVoRow.getBankTransferFeeChargeDiv() != null && 
            ! "".equals(bm1DestVoRow.getBankTransferFeeChargeDiv()))
        {
          bm1DestVoRow.setBankTransferFeeChargeDiv(null);
        }
        // ��s�ԍ�
        if (bm1BankAccVoRow.getBankNumber() != null && 
            ! "".equals(bm1BankAccVoRow.getBankNumber()))
        {
          bm1BankAccVoRow.setBankNumber(null);
        }
        // ���Z�@�֖�
        if (bm1BankAccVoRow.getBankName() != null && 
            ! "".equals(bm1BankAccVoRow.getBankName()))
        {
          bm1BankAccVoRow.setBankName(null);
        }
        // �x�X�ԍ�
        if (bm1BankAccVoRow.getBranchNumber() != null && 
            ! "".equals(bm1BankAccVoRow.getBranchNumber()))
        {
          bm1BankAccVoRow.setBranchNumber(null);
        }
        // �x�X��
        if (bm1BankAccVoRow.getBranchName() != null && 
            ! "".equals(bm1BankAccVoRow.getBranchName()))
        {
          bm1BankAccVoRow.setBranchName(null);
        }
        // �������
        if (bm1BankAccVoRow.getBankAccountType() != null && 
            ! "".equals(bm1BankAccVoRow.getBankAccountType()))
        {
          bm1BankAccVoRow.setBankAccountType(null);
        }
        // �����ԍ�
        if (bm1BankAccVoRow.getBankAccountNumber() != null && 
            ! "".equals(bm1BankAccVoRow.getBankAccountNumber()))
        {
          bm1BankAccVoRow.setBankAccountNumber(null);
        }
        // �������`�J�i
        if (bm1BankAccVoRow.getBankAccountNameKana() != null && 
            ! "".equals(bm1BankAccVoRow.getBankAccountNameKana()))
        {
          bm1BankAccVoRow.setBankAccountNameKana(null);
        }
        // �������`����
        if (bm1BankAccVoRow.getBankAccountNameKanji() != null && 
            ! "".equals(bm1BankAccVoRow.getBankAccountNameKanji()))
        {
          bm1BankAccVoRow.setBankAccountNameKanji(null);
        }
      }
    }
    if ( bm2DestVoRow != null )
    {
      if ( XxcsoContractRegistConstants.BM_PAYMENT_TYPE4.equals(bm2DestVoRow.getBellingDetailsDiv()))
      {
        // �U���萔�����S
        if (bm2DestVoRow.getBankTransferFeeChargeDiv() != null && 
            ! "".equals(bm2DestVoRow.getBankTransferFeeChargeDiv()))
        {
          bm2DestVoRow.setBankTransferFeeChargeDiv(null);
        }
        // ��s�ԍ�
        if (bm2BankAccVoRow.getBankNumber() != null && 
            ! "".equals(bm2BankAccVoRow.getBankNumber()))
        {
          bm2BankAccVoRow.setBankNumber(null);
        }
        // ���Z�@�֖�
        if (bm2BankAccVoRow.getBankName() != null && 
            ! "".equals(bm2BankAccVoRow.getBankName()))
        {
          bm2BankAccVoRow.setBankName(null);
        }
        // �x�X�ԍ�
        if (bm2BankAccVoRow.getBranchNumber() != null && 
            ! "".equals(bm2BankAccVoRow.getBranchNumber()))
        {
          bm2BankAccVoRow.setBranchNumber(null);
        }
        // �x�X��
        if (bm2BankAccVoRow.getBranchName() != null && 
            ! "".equals(bm2BankAccVoRow.getBranchName()))
        {
          bm2BankAccVoRow.setBranchName(null);
        }
        // �������
        if (bm2BankAccVoRow.getBankAccountType() != null && 
            ! "".equals(bm2BankAccVoRow.getBankAccountType()))
        {
          bm2BankAccVoRow.setBankAccountType(null);
        }
        // �����ԍ�
        if (bm2BankAccVoRow.getBankAccountNumber() != null && 
            ! "".equals(bm2BankAccVoRow.getBankAccountNumber()))
        {
          bm2BankAccVoRow.setBankAccountNumber(null);
        }
        // �������`�J�i
        if (bm2BankAccVoRow.getBankAccountNameKana() != null && 
            ! "".equals(bm2BankAccVoRow.getBankAccountNameKana()))
        {
          bm2BankAccVoRow.setBankAccountNameKana(null);
        }
        // �������`����
        if (bm2BankAccVoRow.getBankAccountNameKanji() != null && 
            ! "".equals(bm2BankAccVoRow.getBankAccountNameKanji()))
        {
          bm2BankAccVoRow.setBankAccountNameKanji(null);
        }
      }
    }
    if ( bm3DestVoRow != null )
    {
      if ( XxcsoContractRegistConstants.BM_PAYMENT_TYPE4.equals(bm3DestVoRow.getBellingDetailsDiv()))
      {
        // �U���萔�����S
        if (bm3DestVoRow.getBankTransferFeeChargeDiv() != null && 
            ! "".equals(bm3DestVoRow.getBankTransferFeeChargeDiv()))
        {
          bm3DestVoRow.setBankTransferFeeChargeDiv(null);
        }
        // ��s�ԍ�
        if (bm3BankAccVoRow.getBankNumber() != null && 
            ! "".equals(bm3BankAccVoRow.getBankNumber()))
        {
          bm3BankAccVoRow.setBankNumber(null);
        }
        // ���Z�@�֖�
        if (bm3BankAccVoRow.getBankName() != null && 
            ! "".equals(bm3BankAccVoRow.getBankName()))
        {
          bm3BankAccVoRow.setBankName(null);
        }
        // �x�X�ԍ�
        if (bm3BankAccVoRow.getBranchNumber() != null && 
            ! "".equals(bm3BankAccVoRow.getBranchNumber()))
        {
          bm3BankAccVoRow.setBranchNumber(null);
        }
        // �x�X��
        if (bm3BankAccVoRow.getBranchName() != null && 
            ! "".equals(bm3BankAccVoRow.getBranchName()))
        {
          bm3BankAccVoRow.setBranchName(null);
        }
        // �������
        if (bm3BankAccVoRow.getBankAccountType() != null && 
            ! "".equals(bm3BankAccVoRow.getBankAccountType()))
        {
          bm3BankAccVoRow.setBankAccountType(null);
        }
        // �����ԍ�
        if (bm3BankAccVoRow.getBankAccountNumber() != null && 
            ! "".equals(bm3BankAccVoRow.getBankAccountNumber()))
        {
          bm3BankAccVoRow.setBankAccountNumber(null);
        }
        // �������`�J�i
        if (bm3BankAccVoRow.getBankAccountNameKana() != null && 
            ! "".equals(bm3BankAccVoRow.getBankAccountNameKana()))
        {
          bm3BankAccVoRow.setBankAccountNameKana(null);
        }
        // �������`����
        if (bm3BankAccVoRow.getBankAccountNameKanji() != null && 
            ! "".equals(bm3BankAccVoRow.getBankAccountNameKanji()))
        {
          bm3BankAccVoRow.setBankAccountNameKanji(null);
        }
      }
    }
  }

// 2010-03-01 [E_�{�ғ�_01678] Add End

// Ver.1.3 Add Start
  /*****************************************************************************
   * �K�i���������s���Ǝғo�^�iT�敪�j���`�F�b�N�Ȃ��̏ꍇ�ANULL��ݒ�B
   * @param txn          OADBTransaction�C���X�^���X
   * @param bm1DestVo    ���t��e�[�u�����p�r���[�C���X�^���X
   * @param bm2DestVo    ���t��e�[�u�����p�r���[�C���X�^���X
   * @param bm3DestVo    ���t��e�[�u�����p�r���[�C���X�^���X
   *****************************************************************************
   */
  public static void reflectInvoiceTFlag(
    OADBTransaction                     txn
   ,XxcsoBm1DestinationFullVOImpl       bm1DestVo
   ,XxcsoBm2DestinationFullVOImpl       bm2DestVo
   ,XxcsoBm3DestinationFullVOImpl       bm3DestVo
  )
  {

    XxcsoUtils.debug(txn, "[START]");
    
    // �f�[�^�s���擾
    XxcsoBm1DestinationFullVORowImpl bm1DestVoRow
      = (XxcsoBm1DestinationFullVORowImpl) bm1DestVo.first();

    XxcsoBm2DestinationFullVORowImpl bm2DestVoRow
      = (XxcsoBm2DestinationFullVORowImpl) bm2DestVo.first();

    XxcsoBm3DestinationFullVORowImpl bm3DestVoRow
      = (XxcsoBm3DestinationFullVORowImpl) bm3DestVo.first();

    // ��ʕ\���̃C���{�C�X����VO�ɐݒ肷��
    // �d����}�X�^�̒l���\������Ă���ꍇ�A���t��e�[�u�����X�V����Ȃ�����
    if(bm1DestVoRow != null)
    {
      bm1DestVoRow.setInvoiceTFlag(bm1DestVoRow.getInvoiceTFlag());
      bm1DestVoRow.setInvoiceTNo(bm1DestVoRow.getInvoiceTNo());
      bm1DestVoRow.setInvoiceTaxDivBm(bm1DestVoRow.getInvoiceTaxDivBm());
    }

    if(bm2DestVoRow != null)
    {
      bm2DestVoRow.setInvoiceTFlag(bm2DestVoRow.getInvoiceTFlag());
      bm2DestVoRow.setInvoiceTNo(bm2DestVoRow.getInvoiceTNo());
      bm2DestVoRow.setInvoiceTaxDivBm(bm2DestVoRow.getInvoiceTaxDivBm());
    }

    if(bm3DestVoRow != null)
    {
      bm3DestVoRow.setInvoiceTFlag(bm3DestVoRow.getInvoiceTFlag());
      bm3DestVoRow.setInvoiceTNo(bm3DestVoRow.getInvoiceTNo());
      bm3DestVoRow.setInvoiceTaxDivBm(bm3DestVoRow.getInvoiceTaxDivBm());      
    }

    // �K�i���������s���Ǝғo�^�iT�敪�j���`�F�b�N�Ȃ��̏ꍇ�ANULL��ݒ�
    if (bm1DestVoRow != null 
         && !XxcsoContractRegistConstants.INVOICE_T_FLAG_ON.equals(bm1DestVoRow.getInvoiceTFlag()))
    {
      bm1DestVoRow.setInvoiceTFlag(null);
    }
    if (bm2DestVoRow != null 
         && !XxcsoContractRegistConstants.INVOICE_T_FLAG_ON.equals(bm2DestVoRow.getInvoiceTFlag()))
    {
      bm2DestVoRow.setInvoiceTFlag(null);
    }
    if (bm3DestVoRow != null 
         && !XxcsoContractRegistConstants.INVOICE_T_FLAG_ON.equals(bm3DestVoRow.getInvoiceTFlag()))
    {
      bm3DestVoRow.setInvoiceTFlag(null);
    }

    XxcsoUtils.debug(txn, "[END]");
  }
// Ver.1.3 Add End
}