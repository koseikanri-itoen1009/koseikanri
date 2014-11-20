/*============================================================================
* �t�@�C���� : XxcsoPvRegistCO
* �T�v����   : �p�[�\�i���C�Y�r���[�\����ʃR���g���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-19 1.0  SCS�������l  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.webui;

import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.xxcso012001j.util.XxcsoPvCommonConstants;
import itoen.oracle.apps.xxcso.xxcso012001j.util.XxcsoPvCommonUtils;

import java.io.Serializable;
import java.util.Hashtable;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;


/*******************************************************************************
 * �p�[�\�i���C�Y�r���[�쐬��ʂ̃R���g���[���N���X�ł��B
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoPvSearchCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  /*****************************************************************************
   * ��ʋN�����̏������s���܂��B
   * @param pageContext �y�[�W�R���e�L�X�g
   * @param webBean     ��ʏ��
   *****************************************************************************
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);

    XxcsoUtils.debug(pageContext, "[START]");
    // �o�^�n�����܂�
    if (pageContext.isBackNavigationFired(false))
    {
      XxcsoUtils.unexpected(pageContext, "back navigate");
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    // AM�C���X�^���X�̐���
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    // URL����p�����[�^���擾���܂��B
    String pvDisplayMode
      =  pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY1);
    String viewId
      =  pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY2);

    Serializable[] params = { viewId };

    // �����\���������s
    am.invokeMethod("initDetails" , params);

    // ****************************************
    // *****�v���t�@�C���E�I�v�V�����̐ݒ�*****
    // ****************************************
    boolean errorMode = false;

    // **FND: �r���[�E�I�u�W�F�N�g�ő�t�F�b�`�E�T�C�Y�̐ݒ�
    OAException oaeMsg =
      XxcsoUtils.setAdvancedTableRows(
        pageContext
       ,webBean
       ,XxcsoPvCommonConstants.SELECT_VIEW_ADV_TBL_RN
       ,XxcsoConstants.VO_MAX_FETCH_SIZE
      );

    if (oaeMsg != null)
    {
      pageContext.putDialogMessage(oaeMsg);
      errorMode = true;
    }

    if ( errorMode )
    {
      webBean.findChildRecursive("ApplicationButton").setRendered(false);
      webBean.findChildRecursive("MainSlRN").setRendered(false);
    }

    XxcsoUtils.debug(pageContext, "[END]");

  }

  /*****************************************************************************
   * ��ʃC�x���g�̏������s���܂��B
   * @param pageContext �y�[�W�R���e�L�X�g
   * @param webBean     ��ʏ��
   *****************************************************************************
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processFormRequest(pageContext, webBean);

    // AM�C���X�^���X�̐���
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    // �ėp�����\���敪
    String pvDisplayMode
      =  pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY1);

    // ********************************
    // *****�{�^�������n���h�����O*****
    // ********************************
    // �u����v�{�^��
    if ( pageContext.getParameter("CancelButton") != null )
    {
      am.invokeMethod("handleCancelButton");

      // URL�p�����[�^�̍쐬
      HashMap paramMap
        = XxcsoPvCommonUtils.createParam(
            null
           ,pvDisplayMode
           ,null
          );

      // �������ėp������ʂ֑J��
      pageContext.forwardImmediately(
        XxcsoPvCommonUtils.getInstallBasePgName(pvDisplayMode)
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,paramMap
       ,false
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }

    // �u�K�p�v�{�^��
    if ( pageContext.getParameter("ApplicationButton") != null )
    {
      am.invokeMethod("handleApplicationButton");

      // ���b�Z�[�W�̎擾
      OAException msg = (OAException)am.invokeMethod("getMessage");
      // �J�ڐ��ʂւ̃��b�Z�[�W�̐ݒ�
      XxcsoUtils.setDialogMessage(pageContext, msg);

      // URL�p�����[�^�̍쐬
      HashMap paramMap
        = XxcsoPvCommonUtils.createParam(
            null
           ,pvDisplayMode
           ,null
          );

      // �������ėp������ʂ֑J��
      pageContext.forwardImmediately(
        XxcsoPvCommonUtils.getInstallBasePgName(pvDisplayMode)
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,paramMap
       ,false
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );

    }

    // �u�����v�{�^��
    if ( pageContext.getParameter("CopyButton") != null )
    {
      // �������̃p�����[�^��AM���擾����
      HashMap retMap = (HashMap) am.invokeMethod("handleCopyButton");

      // ���b�Z�[�W
      OAException msg = (OAException)am.invokeMethod("getMessage");
      if (msg != null)
      {
        pageContext.putDialogMessage(msg);
      }
      else
      {
        // URL�p�����[�^�̍쐬
        HashMap paramMap
          = XxcsoPvCommonUtils.createParam(
              (String) retMap.get(XxcsoPvCommonConstants.KEY_EXEC_MODE)
             ,pvDisplayMode
             ,(String) retMap.get(XxcsoPvCommonConstants.KEY_VIEW_ID)
            );

        // �p�[�\�i���C�Y�r���[�쐬��ʂ֑J��
        pageContext.forwardImmediately(
          XxcsoConstants.FUNC_PV_REGIST_PG
         ,OAWebBeanConstants.KEEP_MENU_CONTEXT
         ,null
         ,paramMap
         ,false
         ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
        );
      }
    }

    // �u�r���[�̍쐬�v�{�^��
    if ( pageContext.getParameter("CreateViewButton") != null )
    {
      am.invokeMethod("handleCreateViewButton");

      // URL�p�����[�^�̍쐬
      HashMap paramMap
        = XxcsoPvCommonUtils.createParam(
            XxcsoPvCommonConstants.EXECUTE_MODE_CREATE, pvDisplayMode, "");

      // �p�[�\�i���C�Y�r���[�쐬��ʂ֑J��
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_PV_REGIST_PG
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,paramMap
       ,false
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );

    }

    // ********************************
    // *****Icon(image)�����n���h�����O
    // ********************************
    // �X�V�A�C�R��
    if ( "UpdateIconClick".equals(
            pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))
    )
    {
      String viewId = pageContext.getParameter("SelectedViewId");

      am.invokeMethod("handleUpdateIconClick");

      // URL�p�����[�^�̍쐬
      HashMap paramMap
        = XxcsoPvCommonUtils.createParam(
            XxcsoPvCommonConstants.EXECUTE_MODE_UPDATE
           ,pvDisplayMode
           ,viewId
          );

      // �p�[�\�i���C�Y�r���[�쐬��ʂ֑J��
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_PV_REGIST_PG
        ,OAWebBeanConstants.KEEP_MENU_CONTEXT
        ,null
        ,paramMap
        ,false
        ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }

    // �폜�A�C�R��
    if ( "DeleteIconClick".equals(
            pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))
    )
    {
      String viewId = pageContext.getParameter("SelectedViewId");
      String viewName = pageContext.getParameter("SelectedViewName");

      // �폜�m�F�_�C�A���O�𐶐�
      OAException mainMsg
        = XxcsoMessage.createDeleteWarningMessage(
            XxcsoPvCommonConstants.MSG_VIEW_NAME
           ,viewName
          );
      OADialogPage deleteDialog
        = new OADialogPage(
            OAException.WARNING
           ,mainMsg
           ,null
           ,""
           ,""
          );
          
      String yes = pageContext.getMessage("AK", "FWK_TBX_T_YES", null);
      String no  = pageContext.getMessage("AK", "FWK_TBX_T_NO", null);

      deleteDialog.setOkButtonItemName("DeleteYesButton");
      deleteDialog.setOkButtonToPost(true);
      deleteDialog.setNoButtonToPost(true);
      deleteDialog.setPostToCallingPage(true);
      deleteDialog.setOkButtonLabel(yes);
      deleteDialog.setNoButtonLabel(no);

      Hashtable param = new Hashtable(1);
      param.put(XxcsoPvCommonConstants.KEY_VIEW_ID, viewId);
      param.put(XxcsoPvCommonConstants.KEY_VIEW_NAME, viewName);

      deleteDialog.setFormParameters(param);

      pageContext.redirectToDialogPage(deleteDialog);
    }

    // �폜�m�F��ʂł�OK�{�^������
    if ( pageContext.getParameter("DeleteYesButton") != null )
    {
      String viewId
        = pageContext.getParameter(XxcsoPvCommonConstants.KEY_VIEW_ID);
      String viewName
        = pageContext.getParameter(XxcsoPvCommonConstants.KEY_VIEW_NAME);

      // AM�ւ̃p�����[�^�쐬
      Serializable[] params    = { viewId, pvDisplayMode};
      am.invokeMethod("handleDeleteYesButton", params);

      // ���b�Z�[�W
      OAException msg = (OAException)am.invokeMethod("getMessage");
      pageContext.putDialogMessage(msg);

      // URL�p�����[�^�̍쐬
      HashMap paramMap
        = XxcsoPvCommonUtils.createParam(
            null
           ,pvDisplayMode
           ,null
          );

      // �p�[�\�i���C�Y�r���[�\����ʂ֑J��
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_PV_SEARCH_PG
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,paramMap
       ,true
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );

    }
  }
}
