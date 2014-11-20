/*============================================================================
* �t�@�C���� : XxpoProvisionRtnSummaryCO
* �T�v����   : �x���ԕi�v��:�����R���g���[��
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-17 1.0  �F�{ �a�Y    �V�K�쐬
* 2008-06-06 1.0  ��r ���    �����ύX�v��#137�Ή�
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo443001j.webui;

import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
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
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageDateFieldBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLovInputBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;

/***************************************************************************
 * �x���ԕi�v��:�����R���g���[���N���X�ł��B
 * @author  ORACLE �F�{ �a�Y
 * @version 1.0
 ***************************************************************************
 */
public class XxpoProvisionRtnSummaryCO extends XxcmnOAControllerImpl
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
      TransactionUnitHelper.startTransactionUnit(pageContext, XxpoConstants.TXN_XXPO443001J);

      // ���͕s�ݒ�(�z��No)
      OAMessageTextInputBean shipToNoTextInputBean = (OAMessageTextInputBean)webBean.findChildRecursive("ShShipToNo");
      shipToNoTextInputBean.setDisabled(true);

      // ���͕s�ݒ�(���ɓ�From)
      OAMessageDateFieldBean  arvlDateFromTextInputBean = (OAMessageDateFieldBean )webBean.findChildRecursive("ShArvlDateFrom");
      arvlDateFromTextInputBean.setDisabled(true);

      // ���͕s�ݒ�(���ɓ�To)
      OAMessageDateFieldBean arvlDateToTextInputBean = (OAMessageDateFieldBean)webBean.findChildRecursive("ShArvlDateTo");
      arvlDateToTextInputBean.setDisabled(true);

      // ���͕s�ݒ�(�ʒm�X�e�[�^�X)
      OAMessageChoiceBean notifStatusChoiceBean = (OAMessageChoiceBean)webBean.findChildRecursive("ShNotifStatus");
      notifStatusChoiceBean.setDisabled(true);

      // ���͕s�ݒ�(�w�������R�[�h)
      OAMessageLovInputBean instDeptCodeLovInputBean = (OAMessageLovInputBean)webBean.findChildRecursive("ShInstDeptCode");
      instDeptCodeLovInputBean.setDisabled(true);

      // �|�b�v���X�g��VO�ύX(�����敪)
      OAMessageChoiceBean orderTypeChoiceBean = (OAMessageChoiceBean)webBean.findChildRecursive("ShOrderType");
      orderTypeChoiceBean.setPickListViewUsageName("OrderType2VO1");

      // �|�b�v���X�g��VO�ύX(�X�e�[�^�X)
      OAMessageChoiceBean transStatusChoiceBean = (OAMessageChoiceBean)webBean.findChildRecursive("ShTransStatus");
      transStatusChoiceBean.setPickListViewUsageName("TransStatus2VO1");

      // �N���^�C�v�擾
      String exeType = pageContext.getParameter(XxpoConstants.URL_PARAM_EXE_TYPE);
      // �����ݒ�
      Serializable param[] = { exeType };
      // AM�̎擾
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      // �������������s
      am.invokeMethod("initializeList", param);
      // �������b�Z�[�W�擾
      String cancelMessage = pageContext.getParameter(XxpoConstants.URL_PARAM_CAN_MESSAGE);
      // �������b�Z�[�W�����݂���ꍇ
      if (!XxcmnUtility.isBlankOrNull(cancelMessage))
      {
        // ���b�Z�[�W�{�b�N�X�\��
        pageContext.putDialogMessage(new OAException(cancelMessage, OAException.INFORMATION));
      }

    } else
    {
      // �y���ʏ����z�g�����U�N�V�����`�F�b�N
      if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, XxpoConstants.TXN_XXPO443001J, true))
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
      String exeType = pageContext.getParameter(XxpoConstants.URL_PARAM_EXE_TYPE);

      // �i�ރ{�^���������̏���
      if (pageContext.getParameter("Go") != null)
      {
        // �����������s
        am.invokeMethod("doSearchList");

      // �y�[�W���O�������s��ꂽ�ꍇ
      } else if (GOTO_EVENT.equals(pageContext.getParameter(EVENT_PARAM)))
      {
        am.invokeMethod("checkBoxOff");        

      // �����{�^���������̏���
      } else if (pageContext.getParameter("Delete") != null)
      {
        //�y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO443001J);

        // �p�����[�^�pHashMap����
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_EXE_TYPE, exeType);  //�N���^�C�v
        pageParams.put(XxpoConstants.URL_PARAM_CAN_MESSAGE, null); // ���b�Z�[�W������

        // �ĕ\��
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO443001J,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          false, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES
        );

      // ���z�m��{�^���������̏���
      } else if (pageContext.getParameter("AmountFix") != null)
      {
        // ���z�m�菈�����s
        am.invokeMethod("doAmountFixList");

      // �V�K�{�^���������̏���
      } else if (pageContext.getParameter("New") != null)
      {
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO443001J);

        // �p�����[�^�pHashMap����
        HashMap pageParams = new HashMap();

        pageParams.put(XxpoConstants.URL_PARAM_EXE_TYPE, exeType);  // �N���^�C�v
        pageParams.put(XxpoConstants.URL_PARAM_PREV_URL, XxpoConstants.URL_XXPO443001J);  // ����ʂ�URL

        // �x���ԕi�쐬��ʂ֑J��
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO443001JH,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          false,   // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO,
          OAWebBeanConstants.IGNORE_MESSAGES
        );

      // �˗�No�����N�������̏���
      } else if ("RequestNoLink".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO443001J);
        // �˗�No�擾
        String reqNo = pageContext.getParameter("REQ_NO");
        // �p�����[�^�pHashMap����
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_EXE_TYPE, exeType);  // �N���^�C�v
        pageParams.put(XxpoConstants.URL_PARAM_REQ_NO, reqNo);      // �˗�No
        pageParams.put(XxpoConstants.URL_PARAM_PREV_URL, XxpoConstants.URL_XXPO443001J);  // �����URL

        // �x���ԕi�쐬��ʃw�b�_�֑J��
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO443001JH,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true,   // RetainAM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO,
          OAWebBeanConstants.IGNORE_MESSAGES
        );
      }
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }
  }
}
