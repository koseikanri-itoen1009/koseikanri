/*============================================================================
* �t�@�C���� : XxwshStockLotInputCO
* �T�v����   : ���o�׎��у��b�g���͉��(���Ɏ���)�R���g���[��
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-04-09 1.0  �ɓ��ЂƂ�   �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxwsh.xxwsh920001j.webui;

import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;
import itoen.oracle.apps.xxwsh.util.XxwshConstants;

import java.io.Serializable;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
/***************************************************************************
 * ���o�׎��у��b�g���͉��(���Ɏ���)�R���g���[���N���X�ł��B
 * @author  ORACLE �ɓ� �ЂƂ�
 * @version 1.0
 ***************************************************************************
 */
public class XxwshStockLotInputCO extends XxcmnOAControllerImpl
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

    // �y���ʏ����z�u���E�U�u�߂�v�{�^���`�F�b�N�@�߂�{�^�����������Ă��Ȃ��ꍇ
    if (!pageContext.isBackNavigationFired(false)) 
    {
      // AM�̎擾
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      // �`�F�b�N�{�^�����������ꂽ�ꍇ
      if ((pageContext.getParameter("Check") != null) ||
          (pageContext.getParameter("Check1") != null)) 
      {
        // �������s��Ȃ��B

      // �K�p�{�^�����������ꂽ�ꍇ
      } else if ((pageContext.getParameter("Go") != null)) 
      {
        // �������s��Ȃ�
        
      // �����\���̏ꍇ
      } else
      {
        // �y���ʏ����z�u���E�U�u�߂�v�{�^���`�F�b�N�@�g�����U�N�V�����쐬
        TransactionUnitHelper.startTransactionUnit(pageContext, XxwshConstants.TXN_XXWSH920001J);

        // �p�����[�^�擾      
        HashMap searchParams = new HashMap();
        searchParams.put("orderLineId",      pageContext.getParameter(XxwshConstants.URL_PARAM_LINE_ID));           // �󒍖��׃A�h�I��ID
        searchParams.put("callPictureKbn",   pageContext.getParameter(XxwshConstants.URL_PARAM_CALL_PICTURE_KBN));  // �ďo��ʋ敪
        searchParams.put("headerUpdateDate", pageContext.getParameter(XxwshConstants.URL_PARAM_HEADER_UPDATE_DATE));// �w�b�_�X�V����
        searchParams.put("lineUpdateDate",   pageContext.getParameter(XxwshConstants.URL_PARAM_LINE_UPDATE_DATE));  // ���׍X�V����
        searchParams.put("exeKbn",           pageContext.getParameter(XxwshConstants.URL_PARAM_EXE_KBN));           // �N���敪
        searchParams.put("recordTypeCode",   XxwshConstants.RECORD_TYPE_STOC);                                      // ���R�[�h�^�C�v 30:���Ɏ���

        // �����ݒ�
        Serializable params[] = { searchParams };
        // �����^�ݒ�
        Class[] parameterTypes = { HashMap.class };
        // �����������s
        am.invokeMethod("initialize", params, parameterTypes);
      }
            
    // �y���ʏ����z�u���E�U�u�߂�v�{�^���`�F�b�N�@�߂�{�^�������������ꍇ
    } else
    {
      // �y���ʏ����z�g�����U�N�V�����`�F�b�N
      if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, XxwshConstants.TXN_XXWSH920001J, true))
      { 
        // �y���ʏ����z�G���[�_�C�A���O��ʂ֑J��
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
     
      // �s�}���{�^���������ꂽ�ꍇ
      if (ADD_ROWS_EVENT.equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // �s�ǉ��������s
        am.invokeMethod("addRow");

      // �x���w����ʂ֖߂�{�^�����������ꂽ�ꍇ
      } else if (pageContext.getParameter("Return") != null) 
      {
        String callPictureKbn = pageContext.getParameter(XxwshConstants.URL_PARAM_CALL_PICTURE_KBN); // �ďo��ʋ敪
        String exeKbn         = pageContext.getParameter(XxwshConstants.URL_PARAM_EXE_KBN);          // �N���敪
        String url            = null;

        // �˗�No�擾
        Serializable params[] = { pageContext.getParameter(XxwshConstants.URL_PARAM_LINE_ID) };
        String reqNo          = (String)am.invokeMethod("getReqNo", params); // �˗�No
        
        // URL����
        // �ďo��ʋ敪��2:�x���w���쐬��ʂ̏ꍇ
        if (XxwshConstants.CALL_PIC_KBN_PROD_CREATE.equals(callPictureKbn))
        {
          url = XxpoConstants.URL_XXPO440001JL; // �x���w���쐬���׉��          

        // �ďo��ʋ敪��4:�o�Ɏ��щ�ʂ̏ꍇ
        } else if (XxwshConstants.CALL_PIC_KBN_DELI.equals(callPictureKbn))
        {
          url = XxpoConstants.URL_XXPO441001JL; // �o�Ɏ��ѓ��͖��׉��

        // �ďo��ʋ敪��5:���Ɏ��щ�ʂ̏ꍇ
        } else if (XxwshConstants.CALL_PIC_KBN_STOC.equals(callPictureKbn))
        {
          url = XxpoConstants.URL_XXPO442001JL; // ���Ɏ��ѓ��͖��׉��
        }
        
        //�p�����[�^�pHashMap����
        HashMap pageParams = new HashMap();
        pageParams.put(XxwshConstants.URL_PARAM_EXE_KBN,  exeKbn); // �N���敪
        pageParams.put(XxwshConstants.URL_PARAM_REQ_NO,   reqNo);  // �˗�No

        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxwshConstants.TXN_XXWSH920001J);
          
        // �x���w����ʂ�
        pageContext.setForwardURL(
          url,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES); 

      // �`�F�b�N�{�^�����������ꂽ�ꍇ
      } else if ((pageContext.getParameter("Check") != null) ||
                  (pageContext.getParameter("Check1") != null)) 
      {
        // ���b�g�`�F�b�N�������s
        am.invokeMethod("checkLot");

      // �K�p�{�^�����������ꂽ�ꍇ
      } else if (pageContext.getParameter("Go") != null)
      {
        // ���b�g�`�F�b�N�������s
        am.invokeMethod("checkLot");
        
        // �G���[�`�F�b�N�������s
        String entryFlag = (String)am.invokeMethod("checkError");

        // �����Ώۍs������ꍇ�A�������s
        if ("1".equals(entryFlag))
        {
          // �o�^����
          am.invokeMethod("entryStockData");
        }
      }
      
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }
  }
}

