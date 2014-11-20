/*============================================================================
* �t�@�C���� : XxcsoContractSearchCO
* �T�v����   : �_�񏑏�񌟍��R���g���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-05 1.0  SCS�y���    �V�K�쐬
* 2009-02-17 1.1  SCS�������l  [CT1����]�m�F�_�C�A���O�p�����[�^�C��
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010001j.webui;

import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.xxcso010001j.util.XxcsoContractConstants;

import java.io.Serializable;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

/*******************************************************************************
 * �_�񏑏������������ʂ̃R���g���[���N���X�ł��B
 * @author  SCS�y���
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoContractSearchCO extends OAControllerImpl
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
    XxcsoUtils.debug(pageContext, "[START]");

    super.processRequest(pageContext, webBean);

    // �����܂�
    if (pageContext.isBackNavigationFired(false))
    {
      XxcsoUtils.unexpected(pageContext, "back navigate");
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);      
    }
    //����������
    am.invokeMethod("initDetails");

    //Table���[�W�����̕\���s���ݒ�֐�    
    OAException oaeMsg
      = XxcsoUtils.setAdvancedTableRows(
          pageContext,
          webBean,
          XxcsoContractConstants.REGION_NAME,
          XxcsoContractConstants.VIEW_SIZE
        );

    if ( oaeMsg != null )
    {
      pageContext.putDialogMessage(oaeMsg);
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
    XxcsoUtils.debug(pageContext, "[START]");

    super.processFormRequest(pageContext, webBean);

    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);      
    }
    //�߂�{�^��
    if ( pageContext.getParameter("ReturnButton") != null )
    {
      //���j���[��ʂɑJ��
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_OA_HOME_PAGE,
        OAWebBeanConstants.KEEP_MENU_CONTEXT,
        null,
        null,
        true,
        OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }

    //�i�ރ{�^��
    if ( pageContext.getParameter("SearchButton") != null )
    {
      am.invokeMethod("executeSearch");
    }

    //�����{�^��
    if ( pageContext.getParameter("ClearButton") != null )
    {
      am.invokeMethod("ClearBtn");
    }

    //�_�񏑍쐬�{�^��
    if ( pageContext.getParameter("CreateButton") != null )
    {
      //�Q�Ƃr�o�ꌈ�ԍ��`�F�b�N
      Boolean returnValue = (Boolean)am.invokeMethod("spHeaderCheck");

      if ( ! returnValue.booleanValue() )
      {
        OAException msg = (OAException)am.invokeMethod("getMessage");
        pageContext.putDialogMessage(msg);
      }
      else
      {
        //�p�����[�^�l�擾
        HashMap params = (HashMap)am.invokeMethod("getUrlParamNew");
        //�o�^�X�V��ʂɑJ��
        pageContext.forwardImmediately(
          XxcsoConstants.FUNC_CONTRACT_REGIST_PG,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          params,
          true,
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO
        );
      }
    }

    //�R�s�[�쐬�{�^��
    if ( pageContext.getParameter("CopyButton") != null )
    {
      // AM�֓n���������쐬���܂��B
      Serializable[] mode =
      {
        XxcsoContractConstants.CONSTANT_COM_KBN1
      };
      //���בI���`�F�b�N
      Boolean returnValue = (Boolean)am.invokeMethod("selCheck",mode);

      if ( ! returnValue.booleanValue() )
      {
        OAException msg = (OAException)am.invokeMethod("getMessage");
        pageContext.putDialogMessage(msg);
      }
      else
      {
        //�p�����[�^�l�擾
        HashMap params = (HashMap)am.invokeMethod("getUrlParamCopy");
        //�o�^�X�V��ʂɑJ��
        pageContext.forwardImmediately(
          XxcsoConstants.FUNC_CONTRACT_REGIST_PG,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          params,
          true,
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO
        );
      }
    }

    //�ڍ׃{�^��
    if ( pageContext.getParameter("DetailsButton") != null )
    {
      // AM�֓n���������쐬���܂��B
      Serializable[] mode =
      {
        XxcsoContractConstants.CONSTANT_COM_KBN2
      };
      //���בI���`�F�b�N
      Boolean returnValue = (Boolean)am.invokeMethod("selCheck",mode);

      if ( ! returnValue.booleanValue() )
      {
        OAException msg = (OAException)am.invokeMethod("getMessage");
        pageContext.putDialogMessage(msg);
      }
      else
      {
        // �}�X�^�A�g�`�F�b�N
        returnValue = (Boolean)am.invokeMethod("handleCooperateChk");
        if ( ! returnValue.booleanValue() )
        {
          OAException confirmMsg = (OAException)am.invokeMethod("getMessage");

          this.createConfirmDetailsDialog(
            pageContext
           ,confirmMsg
          );
        }
        else
        {
          //�p�����[�^�l�擾
          HashMap params = (HashMap)am.invokeMethod("getUrlParamDetails");
          //�o�^�X�V��ʂɑJ��
          pageContext.forwardImmediately(
            XxcsoConstants.FUNC_CONTRACT_REGIST_PG,
            OAWebBeanConstants.KEEP_MENU_CONTEXT,
            null,
            params,
            true,
            OAWebBeanConstants.ADD_BREAD_CRUMB_NO
          );
        }
      }
    }

    //PDF�쐬�{�^��
    if ( pageContext.getParameter("PdfButton") != null )
    {
      // AM�֓n���������쐬���܂��B
      Serializable[] mode =
      {
        XxcsoContractConstants.CONSTANT_COM_KBN3
      };
      //���בI���`�F�b�N
      Boolean returnValue = (Boolean)am.invokeMethod("selCheck",mode);

      if ( ! returnValue.booleanValue() )
      {
        OAException msg = (OAException)am.invokeMethod("getMessage");
        pageContext.putDialogMessage(msg);
      }
      else
      {
        // �}�X�^�A�g�`�F�b�N
        returnValue = (Boolean)am.invokeMethod("handleCooperateChk");
        if ( ! returnValue.booleanValue() )
        {
          OAException confirmMsg = (OAException)am.invokeMethod("getMessage");

          this.createConfirmPdfDialog(
            pageContext
           ,confirmMsg
          );
        }
        else
        {
          // PDF������CALL
          XxcsoUtils.debug(pageContext, "PDF�o�͏���");
          am.invokeMethod("handlePdfCreateButton");
        }
      }
    }

    // �m�F�_�C�A���O�ł�OK�{�^���iPDF�j
    if ( pageContext.getParameter("ConfirmPdfOkButton") != null )
    {
      am.invokeMethod("handleConfirmPdfOkButton");
    }

    // �m�F�_�C�A���O�ł�OK�{�^���i�ڍׁj
    if ( pageContext.getParameter("ConfirmDetailsOkButton") != null )
    {
      //�p�����[�^�l�擾
      HashMap params = (HashMap)am.invokeMethod("getUrlParamDetails");
      //�o�^�X�V��ʂɑJ��
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_CONTRACT_REGIST_PG,
        OAWebBeanConstants.KEEP_MENU_CONTEXT,
        null,
        params,
        true,
        OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }

    XxcsoUtils.debug(pageContext, "[END]");
  }

  /*****************************************************************************
   * �m�F�_�C�A���O���������iPDF�j
   * @param pageContext �y�[�W�R���e�L�X�g
   * @param confirmMsg  �m�F��ʕ\���p���b�Z�[�W
   *****************************************************************************
   */
  private void createConfirmPdfDialog(
    OAPageContext pageContext
   ,OAException   confirmMsg
  )
  {
    XxcsoUtils.debug(pageContext, "[START]");
    // �_�C�A���O�𐶐�
    OADialogPage confirmPdfDialog
      = new OADialogPage(
          OAException.CONFIRMATION
         ,confirmMsg
         ,null
         ,""
         ,""
        );
          
    String ok = pageContext.getMessage("AK", "FWK_TBX_T_YES", null);
    String no = pageContext.getMessage("AK", "FWK_TBX_T_NO", null);

    confirmPdfDialog.setOkButtonItemName("ConfirmPdfOkButton");
    confirmPdfDialog.setOkButtonToPost(true);
    confirmPdfDialog.setNoButtonToPost(true);
    confirmPdfDialog.setPostToCallingPage(true);
    confirmPdfDialog.setOkButtonLabel(ok);
    confirmPdfDialog.setNoButtonLabel(no);

    pageContext.redirectToDialogPage(confirmPdfDialog);

    XxcsoUtils.debug(pageContext, "[END]");
  }
  /*****************************************************************************
   * �m�F�_�C�A���O���������i�ڍׁj
   * @param pageContext �y�[�W�R���e�L�X�g
   * @param confirmMsg  �m�F��ʕ\���p���b�Z�[�W
   *****************************************************************************
   */
  private void createConfirmDetailsDialog(
    OAPageContext pageContext
   ,OAException   confirmMsg
  )
  {
    XxcsoUtils.debug(pageContext, "[START]");
    // �_�C�A���O�𐶐�
    OADialogPage confirmDetailsDialog
      = new OADialogPage(
          OAException.CONFIRMATION
         ,confirmMsg
         ,null
         ,""
         ,""
        );
          
    String ok = pageContext.getMessage("AK", "FWK_TBX_T_YES", null);
    String no = pageContext.getMessage("AK", "FWK_TBX_T_NO", null);

    confirmDetailsDialog.setOkButtonItemName("ConfirmDetailsOkButton");
    confirmDetailsDialog.setOkButtonToPost(true);
    confirmDetailsDialog.setNoButtonToPost(true);
    confirmDetailsDialog.setPostToCallingPage(true);
    confirmDetailsDialog.setOkButtonLabel(ok);
    confirmDetailsDialog.setNoButtonLabel(no);

    pageContext.redirectToDialogPage(confirmDetailsDialog);

    XxcsoUtils.debug(pageContext, "[END]");
  }
}
