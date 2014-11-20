/*============================================================================
* �t�@�C���� : XxcsoSpDecisionSearchCO
* �T�v����   : SP�ꌈ�o�^��ʃR���g���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-10 1.0  SCS����_    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.apps.fnd.framework.OAException;
import oracle.jbo.domain.BlobDomain;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.xxcso020001j.util.XxcsoSpDecisionConstants;
import java.io.Serializable;
import com.sun.java.util.collections.HashMap;
import oracle.cabo.ui.data.DataObject;

/*******************************************************************************
 * SP�ꌈ�o�^��ʂ̃R���g���[���N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionRegistCO extends OAControllerImpl
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

    String executeMode
      = XxcsoUtils.getUrlParameter(pageContext, XxcsoConstants.EXECUTE_MODE);
    String spDecisionHeaderId
      = XxcsoUtils.getUrlParameter(
          pageContext, XxcsoConstants.TRANSACTION_KEY1
        );

    XxcsoUtils.debug(pageContext, "ExecuteMode     = " + executeMode);
    XxcsoUtils.debug(pageContext, "TransactionKey1 = " + spDecisionHeaderId);

    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      XxcsoUtils.unexpected(pageContext, "am instance is null");
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    // �|�b�v���X�g�̏�����
    am.invokeMethod("initPopList");

    Serializable[] params =
    {
      spDecisionHeaderId
    };

    if ( XxcsoSpDecisionConstants.COPY_MODE.equals(executeMode) )
    {
      am.invokeMethod("initCopyDetails", params);
    }
    else
    {
      // �@�\�̏�����
      am.invokeMethod("initDetails", params);
    }

    // �\���^��\���A���͉\�^�s�\�̐ݒ�
    am.invokeMethod("setAttributeProperty");
    
    // ���C�A�E�g����
    adjustLayout(pageContext, webBean);

    XxcsoUtils.setAdvancedTableRows(
      pageContext
     ,webBean
     ,"SalesConditionAdvTblRN"
     ,"XXCSO1_VIEW_SIZE_020_A01_01"
    );
    
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

    XxcsoUtils.debug(pageContext, "[START]");

    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      XxcsoUtils.unexpected(pageContext, "am instance is null");
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    String event = pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM);
    XxcsoUtils.debug(pageContext, "EVENT = " + event);

    ////////////////////////////////////////
    // �{�^���C�x���g
    ////////////////////////////////////////
    if ( pageContext.getParameter("ApplyButton") != null )
    {
      // �E�p�{�^�������C�x���g
      HashMap returnValue = (HashMap)am.invokeMethod("handleApplyButton");

      HashMap params
        = (HashMap)returnValue.get(XxcsoSpDecisionConstants.PARAM_URL_PARAM);
      OAException msg
        = (OAException)returnValue.get(XxcsoSpDecisionConstants.PARAM_MESSAGE);

      params.put(
        XxcsoConstants.TRANSACTION_KEY2
        ,pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY2)
      );

      XxcsoUtils.debug(pageContext, "URL PARAM = " + params.toString());

      pageContext.putDialogMessage(msg);
      pageContext.forwardImmediately(
          XxcsoConstants.FUNC_SP_DECISION_REGIST_PG
         ,OAWebBeanConstants.KEEP_MENU_CONTEXT
         ,null
         ,params
         ,true
         ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }

    if ( pageContext.getParameter("CancelButton") != null )
    {
      // ����{�^�������C�x���g
      String searchClass
        = pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY2);

      if ( searchClass == null || "".equals(searchClass) )
      {
        pageContext.forwardImmediately(
          XxcsoConstants.FUNC_OA_HOME_PAGE
         ,OAWebBeanConstants.KEEP_MENU_CONTEXT
         ,null
         ,null
         ,true
         ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
        );
      }
      else
      {
        String forwardPage = XxcsoConstants.FUNC_SP_DECISION_SEARCH_PG1;
        if ( XxcsoSpDecisionConstants.APPROVE_MODE.equals(searchClass) )
        {
          forwardPage = XxcsoConstants.FUNC_SP_DECISION_SEARCH_PG2;
        }
        
        pageContext.forwardImmediately(
          forwardPage
         ,OAWebBeanConstants.KEEP_MENU_CONTEXT
         ,null
         ,null
         ,true
         ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
        );
      }

    }

    if ( pageContext.getParameter("SubmitButton") != null )
    {
      // ��o�{�^�������C�x���g
      HashMap returnValue = (HashMap)am.invokeMethod("handleSubmitButton");

      HashMap params
        = (HashMap)returnValue.get(XxcsoSpDecisionConstants.PARAM_URL_PARAM);
      OAException msg
        = (OAException)returnValue.get(XxcsoSpDecisionConstants.PARAM_MESSAGE);

      params.put(
        XxcsoConstants.TRANSACTION_KEY2
        ,pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY2)
      );

      XxcsoUtils.debug(pageContext, "URL PARAM = " + params.toString());
      
      pageContext.putDialogMessage(msg);
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_SP_DECISION_REGIST_PG
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,params
       ,true
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
    
    if ( pageContext.getParameter("RejectButton") != null )
    {
      // �ی��{�^�������C�x���g
      HashMap returnValue = (HashMap)am.invokeMethod("handleRejectButton");

      HashMap params
        = (HashMap)returnValue.get(XxcsoSpDecisionConstants.PARAM_URL_PARAM);
      OAException msg
        = (OAException)returnValue.get(XxcsoSpDecisionConstants.PARAM_MESSAGE);

      params.put(
        XxcsoConstants.TRANSACTION_KEY2
        ,pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY2)
      );

      XxcsoUtils.debug(pageContext, "URL PARAM = " + params.toString());
      
      pageContext.putDialogMessage(msg);
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_SP_DECISION_REGIST_PG
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,params
       ,true
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
    
    if ( pageContext.getParameter("ApproveButton") != null )
    {
      // ���F�{�^�������C�x���g
      HashMap returnValue = (HashMap)am.invokeMethod("handleApproveButton");

      HashMap params
        = (HashMap)returnValue.get(XxcsoSpDecisionConstants.PARAM_URL_PARAM);
      OAException msg
        = (OAException)returnValue.get(XxcsoSpDecisionConstants.PARAM_MESSAGE);

      params.put(
        XxcsoConstants.TRANSACTION_KEY2
        ,pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY2)
      );

      XxcsoUtils.debug(pageContext, "URL PARAM = " + params.toString());
      
      pageContext.putDialogMessage(msg);
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_SP_DECISION_REGIST_PG
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,params
       ,true
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
    
    if ( pageContext.getParameter("ReturnButton") != null )
    {
      // �ԋp�{�^�������C�x���g
      HashMap returnValue = (HashMap)am.invokeMethod("handleReturnButton");

      HashMap params
        = (HashMap)returnValue.get(XxcsoSpDecisionConstants.PARAM_URL_PARAM);
      OAException msg
        = (OAException)returnValue.get(XxcsoSpDecisionConstants.PARAM_MESSAGE);

      params.put(
        XxcsoConstants.TRANSACTION_KEY2
        ,pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY2)
      );

      XxcsoUtils.debug(pageContext, "URL PARAM = " + params.toString());
      
      pageContext.putDialogMessage(msg);
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_SP_DECISION_REGIST_PG
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,params
       ,true
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
    
    if ( pageContext.getParameter("ConfirmButton") != null )
    {
      // �m�F�{�^�������C�x���g
      HashMap returnValue = (HashMap)am.invokeMethod("handleConfirmButton");

      HashMap params
        = (HashMap)returnValue.get(XxcsoSpDecisionConstants.PARAM_URL_PARAM);
      OAException msg
        = (OAException)returnValue.get(XxcsoSpDecisionConstants.PARAM_MESSAGE);

      params.put(
        XxcsoConstants.TRANSACTION_KEY2
        ,pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY2)
      );

      XxcsoUtils.debug(pageContext, "URL PARAM = " + params.toString());
      
      pageContext.putDialogMessage(msg);
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_SP_DECISION_REGIST_PG
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,params
       ,true
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
    
    if ( pageContext.getParameter("RequestButton") != null )
    {
      // �����˗��{�^�������C�x���g
      HashMap returnValue = (HashMap)am.invokeMethod("handleRequestButton");

      HashMap params
        = (HashMap)returnValue.get(XxcsoSpDecisionConstants.PARAM_URL_PARAM);
      OAException msg
        = (OAException)returnValue.get(XxcsoSpDecisionConstants.PARAM_MESSAGE);

      params.put(
        XxcsoConstants.TRANSACTION_KEY2
        ,pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY2)
      );

      XxcsoUtils.debug(pageContext, "URL PARAM = " + params.toString());
      
      pageContext.putDialogMessage(msg);
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_SP_DECISION_REGIST_PG
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,params
       ,true
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
    
    if ( pageContext.getParameter("ScCalcButton") != null )
    {
      // �艿���Z���v�Z�i�����ʏ����j�{�^�������C�x���g
      am.invokeMethod("handleScCalcButton");
    }
    
    if ( pageContext.getParameter("ScAddRowButton") != null )
    {
      // �s�ǉ��i�����ʏ����j�{�^�������C�x���g
      am.invokeMethod("handleScAddRowButton");
    }
    
    if ( pageContext.getParameter("ScDelRowButton") != null )
    {
      // �s�폜�i�����ʏ����j�{�^�������C�x���g
      am.invokeMethod("handleScDelRowButton");
    }

    if ( pageContext.getParameter("AllCcCalcButton") != null )
    {
      // �艿���Z���v�Z�i�S�e��j�{�^�������C�x���g
      am.invokeMethod("handleAllCcCalcButton");
    }
    
    if ( pageContext.getParameter("SelCcCalcButton") != null )
    {
      // �艿���Z���v�Z�i�S�e��ȊO�j�{�^�������C�x���g
      am.invokeMethod("handleSelCcCalcButton");
    }

    if ( pageContext.getParameter("ReflectContractButton") != null )
    {
      // ��񔽉f�{�^�������C�x���g
      am.invokeMethod("handleReflectContractButton");
    }
    
    if ( pageContext.getParameter("CalcProfitButton") != null )
    {
      // �T�Z�N�ԑ��v�v�Z�{�^�������C�x���g
      am.invokeMethod("handleCalcProfitButton");
    }
    
    if ( pageContext.getParameter("AttachAddButton") != null )
    {
      // �Y�t�ǉ��{�^�������C�x���g
      DataObject fileUploadData = 
        (DataObject)pageContext.getNamedDataObject("AttachFileUp");

      if ( fileUploadData == null )
      {
        throw
          XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00005
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_ATTACH_FILE_NAME
          );
      }
      
      String fileName
        = (String)fileUploadData.selectValue(null, "UPLOAD_FILE_NAME");

      if ( fileName == null || "".equals(fileName.trim()) )
      {
        throw
          XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00005
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_ATTACH_FILE_NAME
          );
      }

      BlobDomain fileData
        = (BlobDomain)fileUploadData.selectValue(null, fileName);

      Serializable[] params =
      {
        fileName
       ,fileData
      };
      Class[] classes =
      {
        String.class
       ,BlobDomain.class
      };

      am.invokeMethod("handleAttachAddButton", params, classes);
    }

    if ( pageContext.getParameter("AttachDelButton") != null )
    {
      // �Y�t�폜�{�^�������C�x���g
      am.invokeMethod("handleAttachDelButton");
    }
    
    ////////////////////////////////////////
    // �����y�[�W�����_�����O�C�x���g
    ////////////////////////////////////////
    if ( "ApplicationTypeChange".equals(event) )
    {
      // �\���敪�ύX�C�x���g
      // �����_�����O�̂�
    }

    if ( "NewoldTypeChange".equals(event) )
    {
      // �V��^����ύX�C�x���g
      // �����_�����O�̂�
    }

    if ( "ElectricityTypeChange".equals(event) )
    {
      // �d�C��敪�ύX�C�x���g
      // �����_�����O�̂�
    }
    
    if ( "BusinessConditionTypeChange".equals(event) )
    {
      // �Ƒԁi�����ށj�ύX�C�x���g
      // �����_�����O�̂�
    }
    
    if ( "SameInstallAccountFlagChange".equals(event) )
    {
      // �ݒu��Ɠ����`�F�b�N�{�b�N�X�ύX�C�x���g
      am.invokeMethod("handleSameInstallAccountFlagChange");
    }

    if ( "ConditionBusinessTypeChange".equals(event) )
    {
      // ��������I��ύX�C�x���g
      am.invokeMethod("handleConditionBusinessTypeChange");
    }

    if ( "AllContainerTypeChange".equals(event) )
    {
      // �S�e��敪�ύX�C�x���g
      am.invokeMethod("handleConditionBusinessTypeChange");
    }

    if ( "Bm1SendTypeChange".equals(event) )
    {
      // ���t��ύX�C�x���g
      am.invokeMethod("handleBm1SendTypeChange");
    }
    
    if ( "Bm1PaymentTypeChange".equals(event) )
    {
      // �x�������E���׏��iBM1�j�ύX�C�x���g
      am.invokeMethod("handleBm1PaymentTypeChange");
    }

    if ( "Bm2PaymentTypeChange".equals(event) )
    {
      // �x�������E���׏��iBM2�j�ύX�C�x���g
      am.invokeMethod("handleBm2PaymentTypeChange");
    }

    if ( "Bm3PaymentTypeChange".equals(event) )
    {
      // �x�������E���׏��iBM3�j�ύX�C�x���g
      am.invokeMethod("handleBm3PaymentTypeChange");
    }

    ////////////////////////////////////////
    // �㏈��
    ////////////////////////////////////////
    am.invokeMethod("afterProcess");
    
    // �\���^��\���A���͉\�^�s�\�̐ݒ�
    am.invokeMethod("setAttributeProperty");
    
    XxcsoUtils.debug(pageContext, "[END]");
  }

  /*****************************************************************************
   * ���C�A�E�g�̒������s���܂��B
   * @param pageContext �y�[�W�R���e�L�X�g
   * @param webBean     ��ʏ��
   *****************************************************************************
   */
  public void adjustLayout(OAPageContext pageContext, OAWebBean webBean)
  {
    String[] objects = XxcsoSpDecisionConstants.CENTERING_OBJECTS;
    for ( int i = 0; i < objects.length; i++ )
    {
      OAWebBean bean = webBean.findIndexedChildRecursive(objects[i]);
      if ( bean instanceof OAMessageLayoutBean )
      {
        ((OAMessageLayoutBean)bean).setVAlign("middle");
      }
    }

    objects = XxcsoSpDecisionConstants.REQUIRED_OBJECTS;
    for ( int i = 0; i < objects.length; i++ )
    {
      OAWebBean bean = webBean.findIndexedChildRecursive(objects[i]);
      if ( bean instanceof OAMessageLayoutBean )
      {
        ((OAMessageLayoutBean)bean).setRequired("uiOnly");
      }
    }

    objects = XxcsoSpDecisionConstants.READONLY_OBJECTS;
    for ( int i = 0; i < objects.length; i++ )
    {
      OAWebBean bean = webBean.findIndexedChildRecursive(objects[i]);
      if ( bean instanceof OAMessageTextInputBean )
      {
        ((OAMessageTextInputBean)bean).setReadOnlyTextArea(true);
        ((OAMessageTextInputBean)bean).setReadOnly(true);
      }
    }
  }
}
