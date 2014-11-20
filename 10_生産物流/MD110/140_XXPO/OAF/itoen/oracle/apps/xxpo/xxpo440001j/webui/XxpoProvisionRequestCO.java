/*============================================================================
* �t�@�C���� : XxpoProvisionRequestCO
* �T�v����   : �x���˗��v��R���g���[��
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-03 1.0  ��r���     �V�K�쐬
* 2008-06-06 1.0  ��r ���    �����ύX�v��#137�Ή�
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo440001j.webui;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;

import java.io.Serializable;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLovInputBean;
/***************************************************************************
 * �x���˗��v���ʂ̃R���g���[���N���X�ł��B
 * @author  ORACLE ��r ���
 * @version 1.0
 ***************************************************************************
 */
public class XxpoProvisionRequestCO extends XxcmnOAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);

    // �y���ʏ����z�u�߂�v�{�^���`�F�b�N
    if (!pageContext.isBackNavigationFired(false)) 
    {
      // �y���ʏ����z�u���E�U�u�߂�v�{�^���`�F�b�N�@�g�����U�N�V�����쐬
      TransactionUnitHelper.startTransactionUnit(pageContext, XxpoConstants.TXN_XXPO440001J);

      // AM�̎擾
      OAApplicationModule am = pageContext.getApplicationModule(webBean);

      // �N���^�C�v�擾
      String exeType = pageContext.getParameter(XxpoConstants.URL_PARAM_EXE_TYPE);
      
      // �N���^�C�v���u12�F�p�b�J�[��O���H��p�v�̏ꍇ
      if (XxpoConstants.EXE_TYPE_12.equals(exeType)) 
      {
        // ���͕s�ݒ�(�����)
        OAMessageLovInputBean vendorLovInputBean = (OAMessageLovInputBean)webBean.findChildRecursive("ShVendorCode");
        vendorLovInputBean.setReadOnly(true);

      }
      // �����ݒ�
      Serializable param[] = { exeType };
      // �������������s
      am.invokeMethod("initializeList", param);
      // �x������������b�Z�[�W�擾
      String mainMessage = pageContext.getParameter(XxpoConstants.URL_PARAM_CAN_MESSAGE);
      // �x������������b�Z�[�W�����݂���ꍇ
      if (!XxcmnUtility.isBlankOrNull(mainMessage))
      {
        // ���b�Z�[�W�{�b�N�X�\��
        pageContext.putDialogMessage(new OAException(mainMessage, OAException.INFORMATION));

      }
    } else
    {
      // �y���ʏ����z�g�����U�N�V�����`�F�b�N
      if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, XxpoConstants.TXN_XXPO440001J, true))
      { 
        pageContext.redirectToDialogPage(new OADialogPage(STATE_LOSS_ERROR));
      } 
    }
  }

  /**
   * Procedure to handle form submissions for form elements in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    try
    {
      super.processFormRequest(pageContext, webBean);

      // AM�̎擾
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      // �N���^�C�v�擾
      String exeType = pageContext.getParameter("ExeType");

      // �i�ރ{�^���������ꂽ�ꍇ
      if (pageContext.getParameter("Go") != null) 
      {
        // �����������s
        am.invokeMethod("doSearchList");

      // �����{�^���������ꂽ�ꍇ
      } else if (pageContext.getParameter("Delete") != null) 
      {
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO440001J);
          
        //�p�����[�^�pHashMap����
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_EXE_TYPE, exeType); // �N���^�C�v
        pageParams.put(XxpoConstants.URL_PARAM_CAN_MESSAGE, null); // ���b�Z�[�W������

        // �ĕ\��
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO440001J,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          false, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);    

      // �m��{�^���������ꂽ�ꍇ
      } else if (pageContext.getParameter("Fix") != null) 
      {
        // �m�菈�����s
        am.invokeMethod("doFixList");

      // ��̃{�^���������ꂽ�ꍇ
      } else if (pageContext.getParameter("Rcv") != null) 
      {
        // ��̏������s
        am.invokeMethod("doRcvList");

      // �蓮�w���m��{�^���������ꂽ�ꍇ
      } else if (pageContext.getParameter("ManualFix") != null) 
      {
        // �蓮�w���m�菈�����s
        am.invokeMethod("doManualFixList");

      // ���i�ݒ�{�^���������ꂽ�ꍇ
      } else if (pageContext.getParameter("PriceSet") != null) 
      {
        // ���i�ݒ菈�����s
        am.invokeMethod("doPriceSetList");

      // ���z�m��{�^���������ꂽ�ꍇ
      } else if (pageContext.getParameter("AmountFix") != null) 
      {
        // ���z�m�菈�����s
        am.invokeMethod("doAmountFixList");

      // �˗�No�����N�������ꂽ�ꍇ
      } else if ("ReqestNoLink".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO440001J);

        // �˗�No�擾
        String reqNo   = pageContext.getParameter("REQ_NO");

        //�p�����[�^�pHashMap����
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_EXE_TYPE, exeType); // �N���^�C�v 
        pageParams.put(XxpoConstants.URL_PARAM_REQ_NO,   reqNo);   // �˗�No
        pageParams.put(XxpoConstants.URL_PARAM_PREV_URL, XxpoConstants.URL_XXPO440001J);   // ����ʂ�URL

        // �x���w���쐬��ʂ֑J��
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO440001JH,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);    

      // �V�K�{�^���������ꂽ�ꍇ
      } else if (pageContext.getParameter("New") != null) 
      {
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO440001J);

        //�p�����[�^�pHashMap����
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_EXE_TYPE, exeType); // �N���^�C�v
        pageParams.put(XxpoConstants.URL_PARAM_PREV_URL, XxpoConstants.URL_XXPO440001J);   // ����ʂ�URL

        // �x���w���쐬��ʂ֑J��
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO440001JH,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          false, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);    

      // �y�[�W���O�������s��ꂽ�ꍇ
      } else if (GOTO_EVENT.equals(pageContext.getParameter(EVENT_PARAM)))
      {
        am.invokeMethod("checkBoxOff");
      }
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }
  }
}
