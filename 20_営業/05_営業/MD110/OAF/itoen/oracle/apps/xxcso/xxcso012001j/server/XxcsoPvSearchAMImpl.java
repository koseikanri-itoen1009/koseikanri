/*============================================================================
* �t�@�C���� : XxcsoPvSearchAMImpl
* �T�v����   : �p�[�\�i���C�Y�r���[�\����ʃA�v���P�[�V�����E���W���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-19 1.0  SCS�������l  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.server;

import itoen.oracle.apps.xxcso.common.poplist.server.XxcsoLookupListVOImpl;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.xxcso012001j.util.XxcsoPvCommonConstants;

import com.sun.java.util.collections.HashMap;

import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jbo.server.ViewLinkImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * �p�[�\�i���C�Y�r���[�\����ʂ̃A�v���P�[�V�����E���W���[���N���X
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoPvSearchAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoPvSearchAMImpl()
  {
  }

  /*****************************************************************************
   * �o�̓��b�Z�[�W
   *****************************************************************************
   */
  private OAException mMessage = null;


  /*****************************************************************************
   * ����������
   * @param viewId �r���[ID
   *****************************************************************************
   */
  public void initDetails(String viewId)
  {
    // PopList������
    this.initPopList();

    // �ėp�����e�[�u���C���X�^���X
    XxcsoPvDefFullVOImpl pvDefFullVo = getPvDefFullVO();
    if ( pvDefFullVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoPvDefFullVOImpl");
    }
    pvDefFullVo.initQuery("", false);

    // �ėp�����e�[�u���s�C���X�^���X
    XxcsoPvDefFullVORowImpl pvDefFullVoRow
      = (XxcsoPvDefFullVORowImpl) pvDefFullVo.first();
    if ( pvDefFullVoRow == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoPvDefFullVOImpl");
    }

    // �擾���J��Ԃ�
    while ( pvDefFullVoRow != null )
    {
      Number lineViewId = pvDefFullVoRow.getViewId();

      // �����I���̃��W�I�{�^��
      if ( viewId != null && viewId.equals(lineViewId.toString()) )
      {
        pvDefFullVoRow.setLineSelectFlag("Y");
      }

      // �f�t�H���g�t���O
      if (XxcsoPvCommonConstants.DEFAULT_FLAG_YES
            .equals( pvDefFullVoRow.getDefaultFlag() )
      )
      {
        // ON(=Y)�̏ꍇ
        pvDefFullVoRow.setDefaultFlagSwitcher(
          XxcsoPvCommonConstants.DEFAULT_FLAG
        );
      }
      else
      {
        pvDefFullVoRow.setDefaultFlagSwitcher(null);
      }

      // �V�[�h�f�[�^�̔�����s���A�X�V�E�폜�A�C�R���̐ݒ���s��
      // �V�[�h�f�[�^�̏ꍇ
      if (lineViewId.intValue() == XxcsoPvCommonConstants.VIEW_ID_SEED)
      {
        // �r���[�̕\��-�g�p�s��
        pvDefFullVoRow.setSeedDataFlag(Boolean.TRUE);

        // �X�V�A�C�R��-�g�p�s��
        pvDefFullVoRow.setUpdateEnableSwitcher(
          XxcsoPvCommonConstants.UPDATE_DISABLED
        );

        // �폜�A�C�R��-�g�p�s��
        pvDefFullVoRow.setDeleteEnableSwitcher(
          XxcsoPvCommonConstants.DELETE_DISABLED
        );
        
      }
      // �V�[�h�f�[�^�ȊO�̃r���[�̏ꍇ
      else
      {
        // �r���[�̕\��-�g�p�\
        pvDefFullVoRow.setSeedDataFlag(Boolean.FALSE);

        // �X�V�A�C�R��-�g�p�\
        pvDefFullVoRow.setUpdateEnableSwitcher(
          XxcsoPvCommonConstants.UPDATE_ENABLED
        );

        // �폜�A�C�R��-�g�p�\
        pvDefFullVoRow.setDeleteEnableSwitcher(
          XxcsoPvCommonConstants.DELETE_ENABLED
        );
        
      }
      pvDefFullVoRow = (XxcsoPvDefFullVORowImpl) pvDefFullVo.next();
    }

  }
  /*****************************************************************************
   * ����{�^������������
   *****************************************************************************
   */
  public void handleCancelButton()
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    this.rollback();

    XxcsoUtils.debug(txt, "[END]");
  }

  /*****************************************************************************
   * �K�p�{�^������������
   *****************************************************************************
   */
  public void handleApplicationButton()
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    this.commit();

    // �������b�Z�[�W��ݒ肷��
    mMessage
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
          ,XxcsoConstants.TOKEN_RECORD
          ,XxcsoConstants.TOKEN_VALUE_PV
          ,XxcsoConstants.TOKEN_ACTION
          ,XxcsoConstants.TOKEN_VALUE_UPDATE
        );

    XxcsoUtils.debug(txt, "[END]");
  }

  /*****************************************************************************
   * �����{�^������������
   * 
   *****************************************************************************
   */
  public HashMap handleCopyButton()
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    // �ԋp�p��hashmap
    HashMap retMap = new HashMap();

    this.rollback();

    // �p�[�\�i���C�Y�r���[�쐬����`�F�b�N
    mMessage = this.chkPvCreate();
    if (mMessage != null)
    {
      return retMap;
    }

    // �ėp�����e�[�u���C���X�^���X
    XxcsoPvDefFullVOImpl pvDefFullVo = getPvDefFullVO();
    if ( pvDefFullVo == null )
    {
      mMessage
        = XxcsoMessage.createInstanceLostError("XxcsoPvDefFullVOImpl");
      return retMap;
    }
    // �ėp�����e�[�u���s�C���X�^���X
    XxcsoPvDefFullVORowImpl pvDefFullVoRow
      = (XxcsoPvDefFullVORowImpl) pvDefFullVo.first();
    if ( pvDefFullVoRow == null )
    {
      mMessage
        = XxcsoMessage.createInstanceLostError("XxcsoPvDefFullVORowImpl");

      return retMap;
    }

    boolean isSelect = false;
    String selViewId = "";
    // �擾���J��Ԃ�
    while ( pvDefFullVoRow != null )
    {
      if ("Y".equals(pvDefFullVoRow.getLineSelectFlag()))
      {
        selViewId = pvDefFullVoRow.getViewId().toString();
        isSelect = true;
        break;
      }
      pvDefFullVoRow = (XxcsoPvDefFullVORowImpl) pvDefFullVo.next();
    }

    // ���W�I�{�^�����I������Ă������`�F�b�N
    if ( !isSelect )
    {
      // ���R�[�h���I���G���[
      mMessage=
        XxcsoMessage.createErrorMessage(
          XxcsoConstants.APP_XXCSO1_00133
         ,XxcsoConstants.TOKEN_ENTRY
         ,XxcsoPvCommonConstants.MSG_RECORD
        );
      return retMap;
    }

    // �r���[ID���V�[�h�f�[�^�̏ꍇ
    if ( Integer.parseInt(selViewId) == XxcsoPvCommonConstants.VIEW_ID_SEED)
    {
      // viewId=�󕶎�
      retMap.put(
        XxcsoPvCommonConstants.KEY_VIEW_ID
       , ""
      );
      // ���s�敪=�V�K�쐬
      retMap.put(
        XxcsoPvCommonConstants.KEY_EXEC_MODE
       ,XxcsoPvCommonConstants.EXECUTE_MODE_CREATE
      );
    }
    else
    {
      // viewId=�I�����ꂽ�r���[ID
      retMap.put(
        XxcsoPvCommonConstants.KEY_VIEW_ID
       ,selViewId
      );
      // ���s�敪=����
      retMap.put(
        XxcsoPvCommonConstants.KEY_EXEC_MODE
       ,XxcsoPvCommonConstants.EXECUTE_MODE_COPY
      );
    }

    XxcsoUtils.debug(txt, "[END]");

    return retMap;

  }

  /*****************************************************************************
   * �r���[�̍쐬�{�^������������
   *****************************************************************************
   */
  public void handleCreateViewButton()
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    this.rollback();

    // �p�[�\�i���C�Y�r���[�쐬����`�F�b�N
    OAException msg = this.chkPvCreate();
    if (msg != null)
    {
      throw msg;
    }

    XxcsoUtils.debug(txt, "[END]");
  }

  /*****************************************************************************
   * �X�V�A�C�R������������
   *****************************************************************************
   */
  public void handleUpdateIconClick()
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    this.rollback();

    XxcsoUtils.debug(txt, "[END]");
  }

  /*****************************************************************************
   * �폜�m�F���OK�{�^������������
   * @param selViewId     �I�����ꂽ�s��viewId
   * @param pvDisplayMode �ėp�����g�p���[�h
   *****************************************************************************
   */
  public void handleDeleteYesButton(
    String selViewId
   ,String pvDisplayMode
    )
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    this.rollback();

    String delViewName = "";
    // �ėp�����e�[�u���C���X�^���X
    XxcsoPvDefFullVOImpl pvDefFullVo = getPvDefFullVO();
    if ( pvDefFullVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoPvDefFullVOImpl");
    }

    // �ėp�����e�[�u���s�C���X�^���X
    XxcsoPvDefFullVORowImpl pvDefFullVoRow
      = (XxcsoPvDefFullVORowImpl) pvDefFullVo.first();
    if ( pvDefFullVoRow == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoPvDefFullVORowImpl");
    }

    // �擾���J��Ԃ�
    while ( pvDefFullVoRow != null )
    {
      // �Ώۂ�viewId��row���폜
      if ( selViewId.equals(pvDefFullVoRow.getViewId().toString()) ) 
      {
        // �폜�O��view����ޔ�
        delViewName = pvDefFullVoRow.getViewName();

        // �ėp�����e�[�u�����׃e�[�u���폜����
        this.removeLine(pvDisplayMode);

        pvDefFullVo.removeCurrentRow();

        this.commit();

        break;
      }
      pvDefFullVoRow = (XxcsoPvDefFullVORowImpl) pvDefFullVo.next();
    }

    // �폜�������b�Z�[�W��ݒ�
    StringBuffer sbMsg = new StringBuffer();
    sbMsg.append(XxcsoPvCommonConstants.MSG_VIEW_NAME);
    sbMsg.append(XxcsoConstants.TOKEN_VALUE_SEP_LEFT);
    sbMsg.append(delViewName);
    sbMsg.append(XxcsoConstants.TOKEN_VALUE_SEP_RIGHT);   

    mMessage
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
          ,XxcsoConstants.TOKEN_RECORD
          ,new String(sbMsg)
          ,XxcsoConstants.TOKEN_ACTION
          ,XxcsoConstants.TOKEN_VALUE_DELETE
        );

    XxcsoUtils.debug(txt, "[END]");
  }

  /*****************************************************************************
   * ���b�Z�[�W���擾���܂��B
   * @return mMessage
   *****************************************************************************
   */
  public OAException getMessage()
  {
    return mMessage;
  }

  /*****************************************************************************
   * �R�~�b�g����
   *****************************************************************************
   */
  private void commit()
  {
    OADBTransaction txt = getOADBTransaction();

    XxcsoUtils.debug(txt, "[START]");

    getTransaction().commit();

    XxcsoUtils.debug(txt, "[END]");
  }

  /*****************************************************************************
   * ���[���o�b�N����
   *****************************************************************************
   */
  private void rollback()
  {
    OADBTransaction txt = getOADBTransaction();

    XxcsoUtils.debug(txt, "[START]");

    if ( getTransaction().isDirty() )
    {
      getTransaction().rollback();
    }

    XxcsoUtils.debug(txt, "[END]");
  }

  /*****************************************************************************
   * Poplist����������
   *****************************************************************************
   */
  private void initPopList()
  {
    // �r���[�̕\��
    XxcsoLookupListVOImpl viewDispLookupVo = getViewDispLookupVO();
    if ( viewDispLookupVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoViewSizeLookupListVO");
    }
    viewDispLookupVo.initQuery("XXCSO1_IB_PV_VIEW_YES_NO", null, "1");
    viewDispLookupVo.executeQuery();
  }

  /*****************************************************************************
   * �p�[�\�i���C�Y�r���[�쐬�`�F�b�N����
   * @retrun �G���[���b�Z�[�W
   *****************************************************************************
   */
  private OAException chkPvCreate()
  {
    OADBTransaction txt = getOADBTransaction();

    XxcsoUtils.debug(txt, "[START]");

    OAException oaeMsg = null;

    // �v���t�@�C���I�v�V�����擾
    String maxFetchSize = txt.getProfile(XxcsoConstants.VO_MAX_FETCH_SIZE);
    if ( maxFetchSize == null || "".equals(maxFetchSize.trim()) )
    {
      return
        XxcsoMessage.createProfileNotFoundError(
          XxcsoConstants.VO_MAX_FETCH_SIZE
        );
    }

    // �ėp�����e�[�u���C���X�^���X
    XxcsoPvDefFullVOImpl pvDefFullVo = getPvDefFullVO();
    if ( pvDefFullVo == null )
    {
      return XxcsoMessage.createInstanceLostError("XxcsoPvDefFullVOImpl");
    }
    // �ėp�����e�[�u���s�C���X�^���X
    XxcsoPvDefFullVORowImpl pvDefFullVoRow
      = (XxcsoPvDefFullVORowImpl) pvDefFullVo.first();
    if ( pvDefFullVoRow == null )
    {
      return XxcsoMessage.createInstanceLostError("XxcsoPvDefFullVOImpl");
    }

    // ���݂̃p�[�\�i���C�Y�r���[���v���t�@�C���T�C�Y�ȉ����`�F�b�N����
    if ( pvDefFullVo.getRowCount() >= Integer.parseInt(maxFetchSize) )
    {
      // �r���[�쐬����G���[
      return
        XxcsoMessage.createErrorMessage(
          XxcsoConstants.APP_XXCSO1_00010
         ,XxcsoConstants.TOKEN_OBJECT
         ,XxcsoConstants.TOKEN_VALUE_PV
         ,XxcsoConstants.TOKEN_MAX_SIZE
         ,maxFetchSize
        );
    }

    XxcsoUtils.debug(txt, "[END]");

    return oaeMsg;

  }



  /*****************************************************************************
   * �ėp�����e�[�u���ɕR���e�[�u���̍폜����
   * �i�ėp�����\�����`�A�ėp�����\�[�g��`�A�ėp�������o������`�̍폜�j
   * @param pvDisplayMode �ėp�����g�pMode
   *****************************************************************************
   */
  private void removeLine(String pvDisplayMode)
  {

    OADBTransaction txt = getOADBTransaction();

    XxcsoUtils.debug(txt, "[START]");

    // �ėp�����\�����`
    XxcsoPvViewColumnFullVOImpl viewColumnVo = getPvViewColumnFullVO();
    if ( viewColumnVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoPvViewColumnFullVOImpl");
    }

    XxcsoPvViewColumnFullVORowImpl viewColumnVoRow
      = (XxcsoPvViewColumnFullVORowImpl) viewColumnVo.first();

    while (viewColumnVoRow != null)
    {
      viewColumnVo.removeCurrentRow();
      viewColumnVoRow = (XxcsoPvViewColumnFullVORowImpl) viewColumnVo.next();
    }

    // �ėp�����\�[�g��`
    XxcsoPvSortColumnFullVOImpl sortColumnVo = getPvSortColumnFullVO();;
    if ( sortColumnVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoPvSortColumnFullVOImpl");
    }
    sortColumnVo.initQuery(pvDisplayMode);

    XxcsoPvSortColumnFullVORowImpl sortColumnVoRow
      = (XxcsoPvSortColumnFullVORowImpl) sortColumnVo.first();

    while (sortColumnVoRow != null)
    {
      sortColumnVo.removeCurrentRow();
      sortColumnVoRow = (XxcsoPvSortColumnFullVORowImpl) sortColumnVo.next();
    }

    //�ėp�������o������`
    XxcsoPvExtractTermFullVOImpl extTermVo = getPvExtractTermFullVO();
    if ( extTermVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPvExtractTermFullVOImpl");
    }
    extTermVo.initQuery(pvDisplayMode);

    XxcsoPvExtractTermFullVORowImpl extTermVoRow
      = (XxcsoPvExtractTermFullVORowImpl) extTermVo.first();

    while (extTermVoRow != null)
    {
      extTermVo.removeCurrentRow();
      extTermVoRow = (XxcsoPvExtractTermFullVORowImpl) extTermVo.next();
    }

    XxcsoUtils.debug(txt, "[END]");
  }


  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso012001j.server", "XxcsoPvSearchAMLocal");
  }


  /**
   * 
   * Container's getter for ViewDispLookupVO
   */
  public XxcsoLookupListVOImpl getViewDispLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("ViewDispLookupVO");
  }











  /**
   * 
   * Container's getter for PvDefFullVO
   */
  public XxcsoPvDefFullVOImpl getPvDefFullVO()
  {
    return (XxcsoPvDefFullVOImpl)findViewObject("PvDefFullVO");
  }

  /**
   * 
   * Container's getter for PvViewColumnFullVO
   */
  public XxcsoPvViewColumnFullVOImpl getPvViewColumnFullVO()
  {
    return (XxcsoPvViewColumnFullVOImpl)findViewObject("PvViewColumnFullVO");
  }

  /**
   * 
   * Container's getter for PvSortColumnFullVO
   */
  public XxcsoPvSortColumnFullVOImpl getPvSortColumnFullVO()
  {
    return (XxcsoPvSortColumnFullVOImpl)findViewObject("PvSortColumnFullVO");
  }

  /**
   * 
   * Container's getter for PvExtractTermFullVO
   */
  public XxcsoPvExtractTermFullVOImpl getPvExtractTermFullVO()
  {
    return (XxcsoPvExtractTermFullVOImpl)findViewObject("PvExtractTermFullVO");
  }

  /**
   * 
   * Container's getter for XxcsoPvDefViewColumnVL1
   */
  public ViewLinkImpl getXxcsoPvDefViewColumnVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoPvDefViewColumnVL1");
  }

  /**
   * 
   * Container's getter for XxcsoPvDefSortColumnVL1
   */
  public ViewLinkImpl getXxcsoPvDefSortColumnVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoPvDefSortColumnVL1");
  }

  /**
   * 
   * Container's getter for XxcsoPvDefExtractTermVL1
   */
  public ViewLinkImpl getXxcsoPvDefExtractTermVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoPvDefExtractTermVL1");
  }

}