/*============================================================================
* �t�@�C���� : XxpoVendorSupplyMakeCO
* �T�v����   : �O���o������:�o�^�R���g���[��
* �o�[�W���� : 1.1
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-08 1.0  �ɓ� �ЂƂ�   �V�K�쐬
* 2008-05-07      �ɓ� �ЂƂ�   �ύX�v���Ή�(#86,90)�A�����ύX�v���Ή�(#28,29,41)
* 2016-05-11 1.1  �R�� �đ�     E_�{�ғ�_13563�Ή�
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo340001j.webui;

import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;

import java.io.Serializable;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
/***************************************************************************
 * �o�������ѕ�:�o�^�R���g���[���N���X�ł��B
 * @author  ORACLE �ɓ� �ЂƂ�
 * @version 1.0
 ***************************************************************************
 */
public class XxpoVendorSupplyMakeCO extends XxcmnOAControllerImpl
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
      // �y���ʏ����z�u���E�U�u�߂�v�{�^���`�F�b�N�@�g�����U�N�V�����쐬
      TransactionUnitHelper.startTransactionUnit(pageContext, XxpoConstants.TXN_XXPO340001J);

      // AM�̎擾
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
    
      // ********************************* //
      // *      �K�p�{�^��������         * //
      // ********************************* //
      if (pageContext.getParameter("Go") != null)
      {
        // �����͍s��Ȃ��B��ʂ��ĕ\��

      // ********************************* //
      // * �_�C�A���O��ʁuYes�v������   * //
      // ********************************* //       
      } else if (pageContext.getParameter("Yes") != null) 
      {
          // �o�^�E�X�V����
          String ret = (String)am.invokeMethod("mainProcess");        

          // ����I���̏ꍇ
          if (XxcmnConstants.RETURN_SUCCESS.equals(ret))
          {
            // �y���ʏ����z�g�����U�N�V�����I��
            TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO340001J);
            
            // �R�~�b�g
            am.invokeMethod("doCommit");
            // �I������
            am.invokeMethod("doEndOfProcess");

          // ����I���łȂ��ꍇ�A���[���o�b�N
          } else
          {
            // �y���ʏ����z�g�����U�N�V�����I��
            TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO340001J);

            // ���[���o�b�N
            am.invokeMethod("doRollBack");
          }        
      // ********************************* //
      // * �_�C�A���O��ʁuNo�v������    * //
      // ********************************* //
      } else if (pageContext.getParameter("No") != null) 
      {
        // �����͍s��Ȃ��B��ʂ��ĕ\��

      // ********************************* //
      // *      �O��ʂ���̑J�ڎ�       * //
      // ********************************* //
      } else
      {
        // �O��ʂ̒l�擾
        String searchTxnsId = pageContext.getParameter(XxpoConstants.URL_PARAM_SEARCH_TXNS_ID); // ����ID
        String updateFlag = pageContext.getParameter(XxpoConstants.URL_PARAM_UPDATE_FLAG); // �X�V�t���O

        // VO����������
        am.invokeMethod("initializeMake");

        // �X�V�t���O��NULL�̏ꍇ
        if (XxcmnUtility.isBlankOrNull(updateFlag))
        {
          // �V�K�s�ǉ�����
          am.invokeMethod("addRow");        
        } else
        {
          // �����ݒ�
          Serializable params[] = { searchTxnsId };
          // ��������
          am.invokeMethod("doSearch", params);        
        }
      }
      
    // �y���ʏ����z�u���E�U�u�߂�v�{�^���`�F�b�N�@�߂�{�^�������������ꍇ
    } else
    {
      // �y���ʏ����z�g�����U�N�V�����`�F�b�N
      if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, XxpoConstants.TXN_XXPO340001J, true))
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
    // AM�̎擾
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    
    try
    {
      super.processFormRequest(pageContext, webBean);

      // ********************************* //
      // *      ����{�^��������         * //
      // ********************************* //
      if (pageContext.getParameter("Cancel") != null) 
      {
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO340001J);
        
        String updateFlag = pageContext.getParameter(XxpoConstants.URL_PARAM_UPDATE_FLAG); // �X�V�t���O
        
        boolean retainAm = true;
        // �X�V�t���O��NULL�̏ꍇ(�V�K�̏ꍇ)
        if (XxcmnUtility.isBlankOrNull(updateFlag))
        {
          // ��ʓ��e��ێ����Ȃ��B
          retainAm = false;
        }
        // �O���o�������ь�����ʂ�
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO340001JS,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          null,
          retainAm, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);    

      // ********************************* //
      // *      �K�p�{�^��������         * //
      // ********************************* //
      } else if (pageContext.getParameter("Go") != null) 
      {
        // �o�^�E�X�V�`�F�b�N����
        HashMap hashMapRet = (HashMap)am.invokeMethod("allCheck");
        // �߂�l�擾
        String plSqlRet = (String)hashMapRet.get("PlSqlRet");

        // �`�F�b�N���x���I���̏ꍇ
        if (XxcmnConstants.RETURN_WARN.equals(plSqlRet))
        {
          // �y���ʏ����z�g�����U�N�V�����I��
          TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO340001J);
        
          // �g�[�N������
          String itemName     = (String)hashMapRet.get("ItemName");
          String lotNumber    = (String)hashMapRet.get("LotNumber");
          String locationName = (String)hashMapRet.get("LocationName");
          MessageToken[] tokens = new MessageToken[3];
          tokens[0] = new MessageToken(XxcmnConstants.TOKEN_LOCATION, locationName); // �ۊǏꏊ
          tokens[1] = new MessageToken(XxcmnConstants.TOKEN_ITEM,     itemName);     // �i��
          tokens[2] = new MessageToken(XxcmnConstants.TOKEN_LOT,      lotNumber);    // ���b�g�ԍ�
          // ���C�����b�Z�[�W�쐬
          OAException mainMessage = new OAException(XxcmnConstants.APPL_XXCMN,
                                                    XxcmnConstants.XXCMN10112,
                                                    tokens);
          // �_�C�A���O���b�Z�[�W��\��
          XxcmnUtility.createDialog(
            OAException.CONFIRMATION,
            pageContext,
            mainMessage,
            null,
            XxpoConstants.URL_XXPO340001JM,
            XxpoConstants.URL_XXPO340001JM,
            "Yes",
            "No",
            "Yes",
            "No",
            null);
            
        // �`�F�b�N������I���̏ꍇ
        } else
        {
          String ret = (String)am.invokeMethod("mainProcess");

          // ����I���̏ꍇ�A�R�~�b�g����
          if (XxcmnConstants.RETURN_SUCCESS.equals(ret))
          {
            // �y���ʏ����z�g�����U�N�V�����I��
            TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO340001J);

            // �R�~�b�g
            am.invokeMethod("doCommit");

            // �R���J�����g�F�W�������C���|�[�g���s
            ret = (String)am.invokeMethod("doImportPo");

            // ����I���̏ꍇ�A�I������
            if (XxcmnConstants.RETURN_SUCCESS.equals(ret))
            {        
              // �I������
              am.invokeMethod("doEndOfProcess");
            }

          // ����I���łȂ��ꍇ�A���[���o�b�N
          } else
          {
            // �y���ʏ����z�g�����U�N�V�����I��
            TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO340001J);

            am.invokeMethod("doRollBack");
          }
        } 

      // ********************************* //
      // *      �l���X�g�ύX��           * //
      // ********************************* //
      } else if (pageContext.isLovEvent())
      {

        String lovInputSourceId = pageContext.getLovInputSourceId();// �C�x���g����LOV��

        // �����ύX��
        if ("TxtVendorCode".equals(lovInputSourceId))
        {
          // �����ύX������
          am.invokeMethod("vendorCodeChanged"); 

        // �H��ύX��
        } else if ("TxtFactoryCode".equals(lovInputSourceId))
        {
          // �H��ύX������
          am.invokeMethod("factoryCodeChanged"); 

        // �i�ڕύX��
        } else if ("TxtItemCode".equals(lovInputSourceId))
        {
          // �i�ڕύX������
          am.invokeMethod("itemCodeChanged"); 
        }
    
      // ********************************* //
      // *      ���Y���ύX��             * //
      // ********************************* //
      } else if ("ManufacturedDateChanged".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // ���Y���ύX������
        am.invokeMethod("manufacturedDateChanged");  

      // ********************************* //
      // *      �������ύX��             * //
      // ********************************* //
      } else if ("ProductedDateChanged".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // �������ύX������
        am.invokeMethod("productedDateChanged");  
 
      }
// 2016-05-11 v1.1 S.Yamashita Add Start
      else if ("ChangedUseByDateChanged".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // �ύX�ܖ������ύX������
        am.invokeMethod("changedUseByDateChanged");
      }
// 2016-05-11 v1.1 S.Yamashita Add End

    // ��O�����������ꍇ  
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
      am.invokeMethod("doRollBack");
    }
  }
}
