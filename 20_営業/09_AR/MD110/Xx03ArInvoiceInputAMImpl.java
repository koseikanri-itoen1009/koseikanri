/*===========================================================================
 * Copyright (c) Oracle Corporation Japan, 2004-2005  All rights reserved
 * FILENAME   Xx03ArInvoiceInputAMImpl.java
 * VERSION    11.5.10.2.10E
 * DATE       2008/02/14
 * HISTORY    2004/12/17                   �V�K�쐬
 *            2005/02/24 ver 1.1           �d�l�ύX�Ή��g��
 *            2005/03/03 ver 1.2           �s��Ή�
 *            2005/03/18 ver 1.3           �O����̖�������`�F�b�N�����ǉ�
 *                                         ����Ŏ����v�Z�̕s��C��
 *                                         �x�����@�̗L�����`�F�b�N�����ǉ�
 *            2005/03/25 ver 1.4           ����Ŏ����v�Z�̕s��C��
 *            2005/04/15 ver 11.5.10.1     �R�s�[�@�\�d�l�ύX�Ή��g��
 *            2005/06/22 ver 11.5.10.1.3   ����Ōv�Z���W�b�N�̕s��C��
 *            2005/07/25 ver 11.5.10.1.4   ����Œ[���v�Z���W�b�N�̏C��
 *            2005/08/04 ver 11.5.10.1.4B  ���ׂ������͂̂Ƃ��ɑ��݃`�F�b�N��
 *                                         ���{����Ȃ��s��̏C��
 *            2005/08/05 ver 11.5.10.1.4C  ���͋��z�Z�o�s��C��
 *            2005/08/10 ver 11.5.10.1.4D  �R�s�[�@�\�̕s��C��
 *            2005/09/07 ver 11.5.10.1.5   �O����ƈꌩ�ڋq���͂ɑΉ����邽�߂ɁA
 *                                         11.5.10.1.4B�̏C�����폜
 *            2005/09/27 ver 11.5.10.1.5B  �Ōv�Z���x���ƒ[���������@�̏���
 *                                         �擾����ۂ̕s��C��
 *            2005/11/11 ver 11.5.10.1.6   �}�X�^�����̉ߋ��f�[�^�\���Ή�
 *            2005/11/22 ver 11.5.10.1.6B  �}�X�^�����f�[�^�Ή��i�ꊇ���F�j
 *            2005/12/08 ver 11.5.10.1.6C  �`�[��ʂ̗L���`�F�b�N�s���Ή�
 *            2005/12/19 ver 11.5.10.1.6D  ���F�Ҕ���̏C���Ή�
 *            2005/12/26 ver 11.5.10.1.6E  �ŋ敪�̗L���`�F�b�N�Ή�
 *            2005/12/27 ver 11.5.10.1.6G  ���j���[���疳���ȓ`�[��ʂ�I�������ۂ�
 *                                         �G���[�Ή�
 *            2005/12/28 ver 11.5.10.1.6H  �G���[���b�Z�[�W�̍ő�擾�����s��Ή�
 *            2006/01/11 ver 11.5.10.1.6I  ��Q578 ���F�Ҕ���̏C��
 *            2006/01/16 ver 11.5.10.1.6J  �����̎擾���@��getFetchedRowCount()����
 *                                         getRowCount()�ɏC��
 *            2006/01/19 ver 11.5.10.1.6K  ����Ŋz�����͂���Ă��Ȃ��ꍇ��
 *                                         ����Ŋz���Z�o����悤�ɏC��
 *            2006/01/23 ver 11.5.10.1.6L  CommonUtil�𗘗p�����Œ胁�b�Z�[�W��
 *                                         ���b�Z�[�W�e�[�u������擾����悤�ύX
 *            2006/01/27 ver 11.5.10.1.6M  ���ׂ̍ő匏���`�F�b�N�Ή�
 *            2006/01/30 ver 11.5.10.1.6N  checkConfValidation���Ŏg�p���Ă���
 *                                         �C�e���[�^selectUpdIter�����\�b�h��
 *                                         �I�������ɂăN���[�Y����悤�ɏC��
 *            2006/02/02 ver 11.5.10.1.6O  �{�^���̃_�u���N���b�N�Ή�
 *            2006/02/14 ver 11.5.10.1.6P  ��Q910�ŋ敪�̓��t�i���݂���߂�
 *            2006/02/28 ver 11.5.10.1.6Q  �ꊇ���F���}�X�^�`�F�b�N�̏����ύX
 *            2006/03/02 ver 11.5.10.1.6R  �e�^�C�~���O�ł̃}�X�^�`�F�b�N����
 *            2006/05/30 ver 11.5.10.2.3   ����ړ����A�{�l�쐬�`�[�͌����ł���悤�ɏC��
 *            2006/08/22 ver 11.5.10.2.4   �m�F��ʂ���\�����̃`�F�b�N���\�b�h�ďo���@�C��
 *            2006/10/04 ver 11.5.10.2.6   �}�X�^�`�F�b�N�̌�����(�L�����̃`�F�b�N�𐿋������t��
 *                                         �s�Ȃ����ڂ�SYSDATE�ōs�Ȃ����ڂ��Ċm�F)
 *            2006/10/17 ver 11.5.10.2.6B  ���׃R�s�[��̉�ʕ\�����R�s�[����1�s�ڂ̑��݂���
 *                                         �y�[�W�Ƃ��A�`�F�b�N�{�b�N�X���N���A����
 *            2006/10/19 ver 11.5.10.2.6C  �ۑ����̃e���|�����R�[�h��VO����擾����悤�ɕύX
 *            2006/10/20 ver 11.5.10.2.6D  ���ׂ̓��̓`�F�b�N���@�̌��Ή�
 *                                         VO���擾���ē��̓`�F�b�N���郁�\�b�h�ǉ�
 *            2006/10/23 ver 11.5.10.2.6E  �d�_�Ǘ��`�F�b�N�̌��A�\�����ɍă`�F�b�N
 *                                         ����悤�ɏC��(���̂��߂̃��\�b�h�ǉ�)
 *            2007/02/09 ver 11.5.10.2.7   �`�[�ԍ��̔Ԏ��Ƀ��b�N�������Ă��Ȃ�����
 *                                         �^�C�~���O�ɂ�蓯��ԍ������Ԃ���鎖�̏C��
 *            2007/08/28 ver 11.5.10.2.10  AR�ʉݗL�����̔�r�Ώۂ͐��������t�Ƃ���C��
 *            2007/11/01 ver 11.5.10.2.10B �ʉ݂̐��x�`�F�b�N(���͉\���x�����`�F�b�N)�ǉ��̂���
 *                                         �ʉݏ����Ɋۂ߂鏈�����폜
 *            2007/12/12 ver 11.5.10.2.10C 11.5.10.2.10B�ł̎d�l���
 *                                         �P���~���ʂ̌��ʂ͒ʉݏ����Ɋۂ߂鏈����ǉ�
 *            2008/01/08 ver 11.5.10.2.10D �[�������̌v�Z���@�̕ύX(�����̒[����������
 *                                         PL/SQL�ƈقȂ錋�ʂƂȂ邽�߂��킹��悤�ɏC��)
 *            2008/02/14 ver 11.5.10.2.10E ����Ŏ����v�Z�����̎��ɐ��������t�̓��̓`�F�b�N��
 *                                         �ŋ敪�̃}�X�^�`�F�b�N��ǉ�
 *            2008/11/10 ver 11.5.10.3     �ڋq�̃Z�L�����e�B�`�F�b�N
 *===========================================================================*/
package oracle.apps.xx03.ar.input.server;
import com.sun.java.util.collections.Vector;

import java.io.Serializable;

import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;

import java.util.ArrayList;
import java.util.Hashtable;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.apps.xx03.util.Xx03ArCommonUtil;
import oracle.apps.fnd.framework.OANLSServices;

import oracle.jbo.Row;
import oracle.jbo.RowSetIterator;
import oracle.jbo.Transaction;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;

import oracle.jbo.server.ViewLinkImpl;

// Ver1.3 add start --------------------------------------------
import java.math.BigDecimal;
// Ver1.3 add end ----------------------------------------------

//ver11.5.10.1.6 Add Start
import oracle.apps.xx03.ar.confirm.server.Xx03ConfirmDispSlipsVOImpl;
import oracle.apps.xx03.ar.confirm.server.Xx03ConfirmDispSlipsVORowImpl;
import oracle.apps.xx03.ar.confirm.server.Xx03ConfirmDispSlipsLineVOImpl;
import oracle.apps.xx03.ar.confirm.server.Xx03ConfirmDispSlipsLineVORowImpl;
import oracle.apps.xx03.ar.confirm.server.Xx03ConfirmUpdSlipsVOImpl;
import oracle.apps.xx03.ar.confirm.server.Xx03ConfirmUpdSlipsVORowImpl;
//ver11.5.10.1.6 Add End

//ver11.5.10.1.6I Add Start
import oracle.apps.xx03.ar.confirm.server.Xx03GetDefaultApproverVOImpl;
import oracle.apps.xx03.ar.confirm.server.Xx03GetDefaultApproverVORowImpl;
//ver11.5.10.1.6I Add End

//ver 11.5.10.1.6I Add Start
import oracle.apps.xx03.util.Xx03CommonUtil;
//ver 11.5.10.1.6I Add End

/**
 *
 * Xx03InvoiceInputPG��AM
 *
 * @version     11.5.10.1.6P
 */
public class Xx03ArInvoiceInputAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public Xx03ArInvoiceInputAMImpl()
  {
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("oracle.apps.xx03.ar.input.server", "Xx03ArInvoiceInputAMLocal");
  }

  /**
   * �����˗��`�[�̍쐬
   * @param slipType �`�[���
   * @return �Ȃ�
   */
  public void createReceivableSlips(String slipType)
  {
    // ��������
    String methodName = "createReceivableSlips";
    startProcedure(getClass().getName(), methodName);

    // �r���[�E�I�u�W�F�N�g�̎擾    
    OAViewObject vo = (OAViewObject)getXx03ReceivableSlipsVO1();
    
    if (!vo.isPreparedForExecution())
    {
      int maxFetchSize = vo.getMaxFetchSize();
      vo.setMaxFetchSize(0);
      vo.executeQuery();
      vo.setMaxFetchSize(maxFetchSize);
    }
    
    Row row = vo.createRow();
    row.setAttribute("SlipType", slipType);
    vo.insertRow(row);
    row.setNewRowState(Row.STATUS_INITIALIZED);

    // �I������
    endProcedure(getClass().getName(), methodName);    
  } // createReceivableSlips()

  /**
   * �����˗��`�[���ׂ̍쐬
   * @param lineCount �쐬�s��
   * @return �Ȃ�
   */
  public void createReceivableSlipLines(Number lineCount)
  {
    // ����������
    String methodName = "createReceivableSlipLines";
    startProcedure(getClass().getName(), methodName);
    
    // ���׍s�쐬
    createReceivableDetailLines(lineCount.intValue(), false);

    // �I������
    endProcedure(getClass().getName(), methodName);    
   } // createReceivableSlipLines()

  /**
   * ���׍s�쐬
   * @param displayLineCount �\���s��
   * @param isForce ���׍s�����쐬
   * @return �Ȃ�
   */
  public void createReceivableDetailLines(int displayLineCount, boolean isForce)
  {
    // ����������
    String methodName = "createReceivableDetailLines";
    startProcedure(getClass().getName(), methodName);
    
    // �p�����[�^�E�`�F�b�N
    if (displayLineCount <= 0)
    {
      // �G���[�E���b�Z�[�W
      MessageToken[] tokens = {new MessageToken("PARAMETER_NAME", "displayLineCount"),
                               new MessageToken("PARAMETER_VALUE", Integer.toString(displayLineCount))};
      throw new OAException("XX03", "APP-XX03-13033", tokens);      
    }
    
    // �r���[�E�I�u�W�F�N�g�̎擾
    OAViewObject vo = (OAViewObject)getXx03ReceivableSlipsLineVO1();

    //Ver11.5.10.2.6B Add Start
    RowSetIterator selectIter = null;
    selectIter = vo.createRowSetIterator("selectIter");
    try
    {
    //Ver11.5.10.2.6B Add End

    // �ǉ���s�̌v�Z
    int addLineCount = 0;                   // �ǉ���s
    int lastLineCount = 0;                  // ���s
    //Ver11.5.10.1.6J 2006/01/16 Change Start
    //int voCount = vo.getFetchedRowCount();  // �r���[�E�I�u�W�F�N�g�E�C���X�^���X�̌���
    int voCount = vo.getRowCount();         // �r���[�E�I�u�W�F�N�g�E�C���X�^���X�̌���
    //Ver11.5.10.1.6J 2006/01/16 Change End
    // �����쐬�ȊO
    if ((!isForce) && (voCount != 0))
    {
      lastLineCount = voCount%displayLineCount;
      addLineCount = displayLineCount-lastLineCount;
    }
    // �����쐬
    else
    {
      lastLineCount = 1;
      addLineCount = displayLineCount;
    }
        //Ver11.5.10.2.6B Del Start ���ʂȏ����̂��ߍ폜
        //vo.first();
        //for (int i=0; i<voCount; i++)
        //{
        //  Xx03ReceivableSlipsLineVORowImpl rowA = (Xx03ReceivableSlipsLineVORowImpl)vo.getCurrentRow();
        //  vo.next();
        //} // for loop
        //Ver11.5.10.2.6B Del End

    // �ǉ���s�̍쐬
    if ((voCount == 0) || (lastLineCount > 0))
    {
      // ��s���쐬����ŏI�s�ֈړ�
      //Ver11.5.10.2.6B Chg Start
      //vo.last();
      //vo.next();
      selectIter.last();
      selectIter.next();
      //Ver11.5.10.2.6B Chg End

      // �쐬
      for (int i=0; i<addLineCount; i++)
      {
        //Ver11.5.10.2.6B Chg Start
        //Row row = (Row)vo.createRow();
        Row row = (Row)selectIter.createRow();
        //Ver11.5.10.2.6B Chg End

        //Ver11.5.10.1.6M Add Start
        try
        {
        //Ver11.5.10.1.6M Add End

          // �f�t�H���g�l�ݒ�
          row.setAttribute("LineNumber", new Number(voCount+i+1));
          row.setAttribute("AutoTaxExec", Xx03ArCommonUtil.STR_NO);

          //Ver11.5.10.2.6B Chg Start
          //vo.insertRow(row);
          selectIter.insertRow(row);
          //Ver11.5.10.2.6B Chg End

        //Ver11.5.10.1.6M Add Start
        }
        catch(Exception e) 
        {
          row.remove();
          throw OAException.wrapperException(e);
        }
        //Ver11.5.10.1.6M Add End
        row.setNewRowState(Row.STATUS_INITIALIZED);

        //Ver11.5.10.2.6B Chg Start
        //vo.next();
        selectIter.next();
        //Ver11.5.10.2.6B Chg End
      }
    }

    //Ver11.5.10.2.6B Del Start
    //// 1���R�[�h�ڂ�\��  
    ////Ver11.5.10.2.6B Chg Start
    ////vo.first();
    //selectIter.first();
    ////Ver11.5.10.2.6B Chg End
    //Ver11.5.10.2.6B Del End

    // Ver11.5.10.1.4b 2005/08/02 add Start
    // �����͎��̒l�`�F�b�N�̂��߁A1�s�ڂ̍s�ԍ��̒l���㏑������B���ۂɒl�̕ύX�͂Ȃ�
    // Ver11.5.10.1.5 2005/09/06 delete start
    // �O����ƈꌩ�ڋq���͂ɑΉ����邽�߁A�����ł̖����̓`�F�b�N���͂���
    //Xx03ReceivableSlipsLineVORowImpl rowB
    //  = (Xx03ReceivableSlipsLineVORowImpl)vo.getCurrentRow();
    //rowB.setAttribute("LineNumber",new Number(1));
    // Ver11.5.10.1.5 2005/09/06 delete End
    // Ver11.5.10.1.4b 2005/08/02 add End

    //Ver11.5.10.2.6B Add Start
    }
    catch(OAException ex)
    {
      throw OAException.wrapperException(ex);
    }
    finally
    {
      if (selectIter != null)
      {
        selectIter.closeRowSetIterator();
      }
    }
    //Ver11.5.10.2.6B Add End

    // �I������
    endProcedure(getClass().getName(), methodName);        
  } // createReceivableDetailLines()

  /**
   * �U�֓`�[�̌���
   * @param receivableId �����ԍ�
   * @param executeQuery 
   * @return �Ȃ�
   */
  public void initReceivableSlips(Number receivableId, Boolean executeQuery)
  {
    // ����������
    String methodName = "initReceivableSlips";
    startProcedure(getClass().getName(), methodName);

    // �r���[�E�I�u�W�F�N�g�̎擾
    Xx03ReceivableSlipsVOImpl vo = getXx03ReceivableSlipsVO1();
    vo.initQuery(receivableId, executeQuery);

    // �I������
    endProcedure(getClass().getName(), methodName);
  } // end initReceivableSlips()

  /**
   * ���͋��z�Z�o
   * @param �Ȃ�
   * @return �Ȃ�
   */
  public void calculateInput()
  {
    // ����������
    String methodName = "calculateInput";
    startProcedure(getClass().getName(), methodName);
    
    Number enteredAmount = new Number(0); // ���͋��z
    Number unitPrice = new Number(0);     // �P��
    Number quantity = new Number(0);      // ����

    //Ver11.5.10.1.4C 2005/08/05 Add Start
    String invoiceCurrencyCode = null;        // ���݂̒ʉ�
    Number selectedPrecision = new Number(0); // ���݂̒ʉ݂̐��x
//ver 11.5.10.2.10D Del Start
//    int roundPrecision = 0;                   // �[�������p�ϐ�
//ver 11.5.10.2.10D Del End
    RowSetIterator selectHeaderIter = null;
    int fetchedHeaderRowCount;
    //Ver11.5.10.1.4C 2005/08/05 Add End

    RowSetIterator selectLineIter = null;
    int fetchedLineRowCount;
    
    try
    {
      // �r���[�E�I�u�W�F�N�g�̎擾
      //Ver11.5.10.1.4C 2005/08/05 Add Start
      OAViewObject headerVo = getXx03ReceivableSlipsVO1();
      
      Xx03ReceivableSlipsVORowImpl headerRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedHeaderRowCount = headerVo.getFetchedRowCount();
      fetchedHeaderRowCount = headerVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectHeaderIter = headerVo.createRowSetIterator("selectHeaderIter");

      if (fetchedHeaderRowCount > 0)
      {
        selectHeaderIter.setRangeStart(0);
        selectHeaderIter.setRangeSize(fetchedHeaderRowCount);

        headerRow = (Xx03ReceivableSlipsVORowImpl)selectHeaderIter.first();
       
        if (headerRow != null){
          // �ʉ݂̎擾
          invoiceCurrencyCode = headerRow.getInvoiceCurrencyCode();
        }
      }  // fetchedHeaderRowCount > 0

      //Ver11.5.10.1.6K 2006/01/19 Add Start
      // �ʉ݂��擾�ł��Ȃ��������̓G���[���b�Z�[�W�\��
      if (invoiceCurrencyCode == null)
      {
        // �ʉݖ����̓G���[�E���b�Z�[�W
        throw new OAException("XX03",
                              "APP-XX03-13017",
                              null,
                              OAException.ERROR,
                              null);
      }
      //Ver11.5.10.1.6K 2006/01/19 Add End
      //Ver11.5.10.1.4C 2005/08/05 Add End

      OAViewObject lineVo = getXx03ReceivableSlipsLineVO1();

      Xx03ReceivableSlipsLineVORowImpl lineRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedLineRowCount = lineVo.getFetchedRowCount();
      fetchedLineRowCount = lineVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectLineIter = lineVo.createRowSetIterator("selectLineIter");


      if (fetchedLineRowCount > 0)
      {
        selectLineIter.setRangeStart(0);
        selectLineIter.setRangeSize(fetchedLineRowCount);

        for (int i=0; i<fetchedLineRowCount; i++)
        {
          lineRow = (Xx03ReceivableSlipsLineVORowImpl)selectLineIter.getRowAtRangeIndex(i);

          if (lineRow != null)
          {
            // *********************************************************************
            // * �P���A���ʂ����͋��z�Z�o
            // *********************************************************************
            // �P��
            unitPrice = lineRow.getSlipLineUnitPrice();
            // ����
            quantity = lineRow.getSlipLineQuantity();

            //Ver11.5.10.1.4C 2005/08/05 Add Start
            // �ʉ݂̐��x�擾
            selectedPrecision = getSelectedPrecision(invoiceCurrencyCode);
            //ver 11.5.10.2.10D Del Start
            //roundPrecision = selectedPrecision.intValue();
            //ver 11.5.10.2.10D Del End
            //Ver11.5.10.1.4C 2005/08/05 Add End
            
            //Ver11.5.10.1.4C 2005/08/05 Modify Start
            if ((unitPrice != null) && (quantity != null))
            {
              // ���͋��z�Z�o�ARow�ɃZ�b�g
              enteredAmount = unitPrice.multiply(quantity);
              //ver 11.5.10.2.10B Del Start
              //enteredAmount = round(enteredAmount,roundPrecision);
              //ver 11.5.10.2.10B Del End
              //ver 11.5.10.2.10C Add Start
              //ver 11.5.10.2.10D Chg Start
              //enteredAmount = round(enteredAmount,roundPrecision);
              enteredAmount = round(enteredAmount,selectedPrecision);
              //ver 11.5.10.2.10D Chg End
              //ver 11.5.10.2.10C Add End
              lineRow.setSlipLineEnteredAmount(enteredAmount);
            }
            //Ver11.5.10.1.4C 2005/08/05 Modify End
          }
        } // for
      } // fetchedLineRowCount > 0

      // �I������
      endProcedure(getClass().getName(), methodName);
    }
    finally
    {
      //Ver11.5.10.1.4C 2005/08/05 Add Start
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();
      }
      //Ver11.5.10.1.4C 2005/08/05 Add End
      if(selectLineIter != null)
      {
        selectLineIter.closeRowSetIterator();
      }
    }
  } // calculateInput()

  /**
   * ����ł̍Čv�Z
   * @param �Ȃ�
   * @return �Ȃ�
   */
  //Ver11.5.10.1.6K 2006/01/19 Change Start
  //public void calculateTax()
  public Vector calculateTax()
  //Ver11.5.10.1.6K 2006/01/19 Change End
  {
    // ����������
    String methodName = "calculateTax()";
    startProcedure(getClass().getName(), methodName);

    //Ver11.5.10.1.6K 2006/01/19 Change Start
    //resetTaxAmount();
    Vector retVec = null;
    retVec = resetTaxAmount();
    //Ver11.5.10.1.6K 2006/01/19 Change End

    // �I������
    endProcedure(getClass().getName(), methodName);

    //Ver11.5.10.1.6K 2006/01/19 Add Start
    return retVec;
    //Ver11.5.10.1.6K 2006/01/19 Add End
  } // calculateTax()

  /**
   * ����ł̍Čv�Z
   * @param �Ȃ�
   * @return �Ȃ�
   */
  //Ver11.5.10.1.6K 2006/01/19 Change Start
  //private void resetTaxAmount()
  private Vector resetTaxAmount()
  //Ver11.5.10.1.6K 2006/01/19 Change End
  {
    // ����������
    String methodName = "resetTaxAmount";
    startProcedure(getClass().getName(), methodName);

    // 
    Number enteredAmount = new Number(0);     // ���͋��z
    Number enteredItemAmount = new Number(0); // �{�̐Ŋz
    Number enteredTaxAmount = new Number(0);  // ����Ŋz
    String taxCode = null;                    // �ŋ敪
    Number taxRate = new Number(0);           // �ŗ�
    String taxFlag = null;                    // ���Ńt���O
    String autoTaxCalcFlag = null;            // ����Ōv�Z���x��
    String taxRoundingRule = null;            // ����Œ[������
    // ver1.3 add start ---------------------------------------------------------
    String invoiceCurrencyCode = null;        // ���݂̒ʉ�
    Number selectedPrecision = new Number(0); // ���݂̒ʉ݂̐��x
//ver 11.5.10.2.10D Del Start
//    int roundPrecision = 0;                   // �[�������p�ϐ�
//    double roundNumber = 1;                   // �[�������p�ϐ�
//ver 11.5.10.2.10D Del End
    // ver1.3 add end -----------------------------------------------------------
    boolean isExistExcludingTax = false;      // �O�Ŗ��ב��݃`�F�b�N

    //Ver11.5.10.1.6K 2006/01/19 Add Start
    Vector retVec = new Vector();
    //Ver11.5.10.1.6K 2006/01/19 Add End

    Number coordinateValue = new Number(0);   // ����Œ����z
    int coordinateId = 0;                     // ����Œ����Ώ�

    // �����v�Z���w�b�_�P�ʂ̏ꍇ�ɁA�O�ł̋��z��ۑ�����
    Number enteredAmountExTax = new Number(0);
    Number enteredTaxAmountExTax = new Number(0);
    // �����v�Z���w�b�_�P�ʂ̏ꍇ�ɁA�[�������ς̊O�ł̋��z��ۑ�����
    Number autoEnteredAmountExTax = new Number(0);
    Number autoEnteredTaxAmountExTax = new Number(0);

    RowSetIterator selectHeaderIter = null;    
    RowSetIterator selectLineIter = null;
    int fetchedHeaderRowCount;
    int fetchedLineRowCount;

    // Ver11.5.10.1.3 add START
    //�����v�Z���w�b�_�P�ʂ̏ꍇ�ɕK�v�ȕϐ�
    Number headerAmount = new Number(0);      // ���ׂ̋��z���v
    Number headerTaxAmount = new Number(0);   // ���v���z�ɑ΂������Ŋz
    // �Ŋz�v�Z�ŗ��p����n�b�V���e�[�u��
    Hashtable headerAmountTable = new Hashtable();
    Hashtable headerTaxAmountTable = new Hashtable();
    // �n�b�V���e�[�u���̃L�[
    String tableKey = null;
    // Ver11.5.10.1.3 add END

    //Ver11.5.10.1.6E 2005/12/26 Add Start
    Date headInvDate = null;
    //Ver11.5.10.1.6E 2005/12/26 Add End

    //Ver11.5.10.1.6K 2006/01/19 Add Start
    // �ŋ敪Null���݃`�F�b�N�t���O
    String taxNullFlag = null;
    //Ver11.5.10.1.6K 2006/01/19 Add End

    try
    {
      // �r���[�E�I�u�W�F�N�g�̎擾
      OAViewObject headerVo = getXx03ReceivableSlipsVO1();
      OAViewObject lineVo = getXx03ReceivableSlipsLineVO1();

      Xx03ReceivableSlipsVORowImpl headerRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedHeaderRowCount = headerVo.getFetchedRowCount();
      fetchedHeaderRowCount = headerVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectHeaderIter = headerVo.createRowSetIterator("selectHeaderIter");

      Xx03ReceivableSlipsLineVORowImpl lineRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedLineRowCount = lineVo.getFetchedRowCount();
      fetchedLineRowCount = lineVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectLineIter = lineVo.createRowSetIterator("selectLineIter");

      if (fetchedHeaderRowCount > 0)
      {
        selectHeaderIter.setRangeStart(0);
        selectHeaderIter.setRangeSize(fetchedHeaderRowCount);

        headerRow = (Xx03ReceivableSlipsVORowImpl)selectHeaderIter.first();
        Hashtable returnHashtable = null;

        if (headerRow != null){
          // ver1.3 add start ---------------------------------------------------------
          // �ʉ݂̎擾
          invoiceCurrencyCode = headerRow.getInvoiceCurrencyCode();
          // ver1.3 add end -----------------------------------------------------------
          // ����Ōv�Z���x���A����Œ[�������̐ݒ�
          // �u�㏑�̋��v�I�v�V�����擾
          String strTaxOverride = getTaxOverride();
          if (strTaxOverride.equals(Xx03ArCommonUtil.STR_YES))
          {
            // �㏑�̋���'Y'�̏ꍇ�͌ڋq���Ə��A�ڋq�̒l����
            Number customerId = headerRow.getCustomerId();
            Number customerOfficeId = headerRow.getCustomerOfficeId();
            // �ڋq���Ə��̏���Ōv�Z���x���A����Œ[�������擾
            returnHashtable = getCustomerTaxOption(customerId, customerOfficeId);
            //Ver11.5.10.1.5B 2005/09/27 Change Start
            // ����Ōv�Z���x���A����Œ[�������̂��ꂼ�ꂪNull��������
            // ���̗D�揇�ʂ̃}�X�^���Q�Ƃ���
            if (returnHashtable != null)
            {
              // �߂�l������Ɏ擾����Ă���ꍇ�A�߂�l�̒l���g�p
              // ����Ōv�Z���x��
              if((returnHashtable.get("taxCalcFlag") != null)
                && (!returnHashtable.get("taxCalcFlag").equals("")))
              {
                autoTaxCalcFlag = (String)returnHashtable.get("taxCalcFlag");
              }
              // ����Œ[������
              if((returnHashtable.get("taxRoundingRule") != null)
                && (!returnHashtable.get("taxRoundingRule").equals("")))
              {
                taxRoundingRule = (String)returnHashtable.get("taxRoundingRule");
              }
            }
            //if ((returnHashtable != null)
            //    && (returnHashtable.get("taxCalcFlag") != null)
            //    && (!returnHashtable.get("taxCalcFlag").equals(""))
            //    && (returnHashtable.get("taxRoundingRule") != null)
            //    && (!returnHashtable.get("taxRoundingRule").equals("")))
            //{
            //  // �߂�l������Ɏ擾����Ă���ꍇ�A�߂�l�̒l���g�p
            //  autoTaxCalcFlag = (String)returnHashtable.get("taxCalcFlag");
            //  taxRoundingRule = (String)returnHashtable.get("taxRoundingRule");
            //}
            //Ver11.5.10.1.5B 2005/09/27 Change End
          }

          // �ڋq���Ə��A�ڋq�ɒl���ݒ肳��Ă��Ȃ��ꍇ�A�㏑�̋���'N'�̏ꍇ��
          // �V�X�e���I�v�V�����̒l�擾
          if ((autoTaxCalcFlag == null) || (autoTaxCalcFlag.equals(""))
              || (taxRoundingRule == null) || (taxRoundingRule.equals("")))
          {
            // �V�X�e���I�v�V�����̏���Ōv�Z���x���A����Œ[�������擾
            returnHashtable = getSystemTaxOption();
            if ((returnHashtable != null)
                && (returnHashtable.get("taxCalcFlag") != null)
                && (!returnHashtable.get("taxCalcFlag").equals(""))
                && (returnHashtable.get("taxRoundingRule") != null)
                && (!returnHashtable.get("taxRoundingRule").equals("")))
            {
              //Ver11.5.10.1.5B 2005/09/27 Change Start
              // ����Ōv�Z���x���ɒl���ݒ肳��Ă��Ȃ���΃V�X�e���I�v�V�����̒l��ݒ肷��
              if((autoTaxCalcFlag == null) || (autoTaxCalcFlag.equals("")))
              {
                  autoTaxCalcFlag = (String)returnHashtable.get("taxCalcFlag");
              }
              // ����Œ[�������ɒl���ݒ肳��Ă��Ȃ���΃V�X�e���I�v�V�����̒l��ݒ肷��
              if((taxRoundingRule == null) || (taxRoundingRule.equals("")))
              {
                  taxRoundingRule = (String)returnHashtable.get("taxRoundingRule");
              }
              // // �߂�l������Ɏ擾����Ă���ꍇ�A�߂�l�̒l���g�p
              // autoTaxCalcFlag = (String)returnHashtable.get("taxCalcFlag");
              // taxRoundingRule = (String)returnHashtable.get("taxRoundingRule");
              //Ver11.5.10.1.5B 2005/09/27 Change End
            }
          }

          //Ver11.5.10.1.6E 2005/12/26 Add Start
          headInvDate = headerRow.getInvoiceDate();
          //Ver11.5.10.1.6E 2005/12/26 Add End

        } // headerRow       
      } // fetchedHeaderRocCount
      else
      {
        // �G���[�E���b�Z�[�W
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);
      } // fetchedHeaderRowCount

      //Ver11.5.10.1.6K 2006/01/19 Add Start
      // �ʉ݂��擾�ł��Ȃ��������̓G���[���b�Z�[�W�\��
      if (invoiceCurrencyCode == null)
      {
        // �ʉݖ����̓G���[�E���b�Z�[�W
        throw new OAException("XX03",
                              "APP-XX03-13017",
                              null,
                              OAException.ERROR,
                              null);
      }
      //Ver11.5.10.1.6K 2006/01/19 Add End

      //ver 11.5.10.2.10E Add Start
      // ���������t���擾�ł��Ȃ��������̓G���[���b�Z�[�W�\��
      if (headInvDate == null)
      {
        // ���������t�����̓G���[�E���b�Z�[�W
        throw new OAException("XX03",
                              "APP-XX03-13013",
                              null,
                              OAException.ERROR,
                              null);
      }
      //ver 11.5.10.2.10E Add End

      //Ver11.5.10.1.6K 2006/01/19 Add Start
      if (fetchedLineRowCount > 0)
      {
        selectLineIter.setRangeStart(0);
        selectLineIter.setRangeSize(fetchedLineRowCount);

        //ver 11.5.10.2.10E Add Start
        //�G���[�������p�̕ϐ��錾
        OAException msg;
        MessageToken slipNumTok = new MessageToken("SLIP_NUM","");
        MessageToken countTok;
        //ver 11.5.10.2.10E Add End

        for (int i=0; i<fetchedLineRowCount; i++)
        {
          lineRow = (Xx03ReceivableSlipsLineVORowImpl)selectLineIter.getRowAtRangeIndex(i);

          //ver 11.5.10.2.10E Add Start
          //�G���[�������p�̍s����p��
          countTok = new MessageToken("TOK_COUNT",lineRow.getLineNumber().toString());
          //ver 11.5.10.2.10E Add End

          if (lineRow != null)
          {
            if  ((lineRow.getSlipLineUnitPrice() != null)
                && (lineRow.getSlipLineQuantity() != null)
                && (lineRow.getTaxCode() == null))
            {
              //ver 11.5.10.2.10E Chg Start
              //MessageToken slipNumTok = new MessageToken("SLIP_NUM","");
              //MessageToken countTok = new MessageToken("TOK_COUNT",
              //                         lineRow.getLineNumber().toString());
              //OAException msg = new OAException("XX03",
              //                      "APP-XX03-14151",
              //                      new MessageToken[]{slipNumTok ,countTok},
              //                      OAException.ERROR,
              //                      null);
              msg = new OAException("XX03",
                                    "APP-XX03-14151",
                                    new MessageToken[]{slipNumTok ,countTok},
                                    OAException.ERROR,
                                    null);
              //ver 11.5.10.2.10E Chg End
              retVec.addElement(msg);

              taxNullFlag = "1";
            }

            //ver 11.5.10.2.10E Add Start
            // �ŋ��R�[�h�`�F�b�N
            if (    (headerRow.getInvoiceDate() != null) && (!headerRow.getInvoiceDate().equals(""))
                 && (lineRow.getTaxName()       != null) && (!lineRow.getTaxName().equals("")      )
                 && (lineRow.getTaxCode()       != null) && (!lineRow.getTaxCode().equals("")      ) )
            {
              ArrayList slipLineTaxInfo = getSlipLineTaxName(lineRow.getTaxName(), lineRow.getTaxCode(), headerRow.getInvoiceDate());
              if (slipLineTaxInfo.isEmpty())
              {
                msg = new OAException( "XX03" ,"APP-XX03-14151"
                                      ,new MessageToken[]{slipNumTok ,countTok} ,OAException.ERROR ,null);
                retVec.addElement(msg);
                taxNullFlag = "1";
              }
              else
              {
                Number getTaxId = (Number)slipLineTaxInfo.get(1);
                String getIncTaxFlag = (String)slipLineTaxInfo.get(2);
                if (!lineRow.getTaxId().equals(getTaxId))
                {
                  msg = new OAException( "XX03" ,"APP-XX03-14151"
                                        ,new MessageToken[]{slipNumTok ,countTok} ,OAException.ERROR ,null);
                  retVec.addElement(msg);
                  taxNullFlag = "1";
                }
                else if (!getIncTaxFlag.equals(lineRow.getAmountIncludesTaxFlag()))
                {
                  msg = new OAException( "XX03" ,"APP-XX03-13070"
                                        ,new MessageToken[]{slipNumTok ,countTok} ,OAException.ERROR ,null);
                  retVec.addElement(msg);
                  taxNullFlag = "1";
                }
              }
            }
            //ver 11.5.10.2.10E Add End

          } // lineRow != null
        } // for loop
      }

    //�ŋ敪Null�����鎞�͌v�Z�͍s��Ȃ�
    if (taxNullFlag == null)
    {
    //Ver11.5.10.1.6K 2006/01/19 Add End

      if (fetchedLineRowCount > 0)
      {
        selectLineIter.setRangeStart(0);
        selectLineIter.setRangeSize(fetchedLineRowCount);

        for (int i=0; i<fetchedLineRowCount; i++)
        {
          lineRow = (Xx03ReceivableSlipsLineVORowImpl)selectLineIter.getRowAtRangeIndex(i);

          if (lineRow != null)
          {
            if ((lineRow.getSlipLineUnitPrice() != null)
                && (lineRow.getSlipLineQuantity() != null)
                && (lineRow.getTaxCode() != null))
            {
              // *********************************************************************
              // * ����ł̎Z�o
              // *********************************************************************
              // ���͋��z�擾
              // ���؏�����EO�ɂĎ��s
              enteredAmount = lineRow.getSlipLineEnteredAmount();

              // �Ŋz�擾
              enteredTaxAmount = lineRow.getEnteredTaxAmount();
              
              // ver1.3 add start ---------------------------------------------------------
              // �ʉ݂̐��x�擾
              selectedPrecision = getSelectedPrecision(invoiceCurrencyCode);
//ver 11.5.10.2.10D Del Start
//              roundPrecision = selectedPrecision.intValue();
//              // Ver1.4 change start ------------------------------------------------------
//              if(roundPrecision>0)
//              {
//                BigDecimal scale = new BigDecimal("1");
//                scale = scale.movePointRight(roundPrecision);
//                roundNumber = scale.doubleValue();
//              }              
//ver 11.5.10.2.10D Del End
//              if(roundPrecision>0)
//              {
//                BigDecimal scale = new BigDecimal("10");
//                scale.movePointRight(roundPrecision);
//                roundNumber = scale.doubleValue();
//              }
              // Ver1.4 change end --------------------------------------------------------
              // ver1.3 add end -----------------------------------------------------------

              // �ŋ敪�擾
              // ���؏�����EO�ɂĎ��s
              taxCode = lineRow.getTaxCode();

              // ���Ńt���O
              // ver 1.2 Change Start ���Ńt���O��ŋ敪����擾����悤�ύX
              //              taxFlag = lineRow.getAmountIncludesTaxFlag();
              //Ver11.5.10.1.6E 2005/12/26 Change Start
//              taxFlag = getIncludesTaxFlag(taxCode);
              if(headInvDate != null)
              {
                taxFlag = getIncludesTaxFlag(taxCode, headInvDate);
              }
              //Ver11.5.10.1.6E 2005/12/26 Change End
              // ver 1.2 Change End

              //Ver11.5.10.1.3 modify START
              //if (enteredAmount != null
              // ���͋��z��NULL�łȂ��A���Ōv�Z���x�����u���ׁv�̏ꍇ
              if (enteredAmount != null && Xx03ArCommonUtil.AUTO_TAX_CALC_ON_LINE.compareTo(autoTaxCalcFlag) == 0)
              //Ver11.5.10.1.3 modify END
              {
                //Ver11.5.10.1.6E 2005/12/26 Change Start
//                // �ŗ��擾
//                taxRate = getTaxRate(lineRow.getTaxCode());
                if(headInvDate != null)
                {
//                taxRate = getTaxRate(lineRow.getTaxCode());
                  taxRate = getTaxRate(lineRow.getTaxCode(), headInvDate);
                }
                //Ver11.5.10.1.6E 2005/12/26 Change End
                // ���ł̏ꍇ
                if (Xx03ArCommonUtil.STR_YES.compareTo(taxFlag) == 0)
                {
                  enteredTaxAmount = enteredAmount.multiply(taxRate).divide(taxRate.add(100));
                  //ver 11.5.10.2.10B Del Start
                  //enteredItemAmount = enteredAmount.subtract(enteredTaxAmount);
                  //ver 11.5.10.2.10B Del End
                }
                // �O�ł̏ꍇ
                else
                {
                  enteredTaxAmount = enteredAmount.multiply(taxRate).divide(100);
                  //ver 11.5.10.2.10B Del Start
                  //enteredItemAmount = enteredAmount;
                  //ver 11.5.10.2.10B Del End

                  // �O�Ŗ��ׂ̑��݃`�F�b�N
                  isExistExcludingTax = true;

                  // ����Œ����Ώۂ̖��ׂ�ێ�
                  coordinateId = i;
                }
      // ver1.3 change start ------------------------------------------------------
                // �[�������K�����؂艺���̏ꍇ
                if (Xx03ArCommonUtil.ROUND_DOWN.compareTo(taxRoundingRule) == 0)
                {
                  //Ver11.5.10.1.4 2005/07/25 Modify Start
                  // ����Ōv�Z���W�b�N�̕ύX
                  //enteredTaxAmount = (Number)enteredTaxAmount.subtract(Xx03ArCommonUtil.ROUND_NUMBER/roundNumber).round(roundPrecision);
                  //ver 11.5.10.2.10D Chg Start
                  //enteredTaxAmount = roundDown(enteredTaxAmount,roundNumber);
                  enteredTaxAmount = roundDown(enteredTaxAmount,selectedPrecision);
                  //ver 11.5.10.2.10D Chg End
                  // ���ł̏ꍇ�́A�{�̂̐؂�グ���K�v
                  // �O�ł̏ꍇ�́A�{�̂̐؂�グ�͕s�v�����A���ꂵ�čs��
                  //enteredItemAmount = (Number)enteredItemAmount.add(Xx03ArCommonUtil.ROUND_NUMBER/roundNumber).round(roundPrecision);
                  //ver 11.5.10.2.10B Del Start
                  //enteredItemAmount = roundUp(enteredItemAmount,roundNumber);
                  //ver 11.5.10.2.10B Del End
                  //Ver11.5.10.1.4 2005/07/25 Modify End
                }
                // �[�������K�����؂�グ�̏ꍇ
                else if (Xx03ArCommonUtil.ROUND_UP.compareTo(taxRoundingRule) == 0)
                {
                  //Ver11.5.10.1.4 2005/07/25 Modify Start
                  // ����Ōv�Z���W�b�N�̕ύX
                  //enteredTaxAmount = (Number)enteredTaxAmount.add(Xx03ArCommonUtil.ROUND_NUMBER/roundNumber).round(roundPrecision);                
                  //ver 11.5.10.2.10D Chg Start
                  //enteredTaxAmount = roundUp(enteredTaxAmount,roundNumber);
                  enteredTaxAmount = roundUp(enteredTaxAmount,selectedPrecision);
                  //ver 11.5.10.2.10D Chg End
                  // ���ł̏ꍇ�́A�{�̂̐؂艺�����K�v
                  // �O�ł̏ꍇ�́A�{�̂̐؂艺���͕s�v�����A���ꂵ�čs��
                  //enteredItemAmount = (Number)enteredItemAmount.subtract(Xx03ArCommonUtil.ROUND_NUMBER/roundNumber).round(roundPrecision);
                  //ver 11.5.10.2.10B Del Start
                  //enteredItemAmount = roundDown(enteredItemAmount,roundNumber);
                  //ver 11.5.10.2.10B Del End
                  //Ver11.5.10.1.4 2005/07/25 Modify End
                }
                // �[�������K�����l�̌ܓ��̏ꍇ
                else if (Xx03ArCommonUtil.ROUND.compareTo(taxRoundingRule) == 0)
                {
                  //Ver11.5.10.1.4 2005/07/25 Modify Start
                  // ����Ōv�Z���W�b�N�̕ύX
                  //enteredTaxAmount = (Number)enteredTaxAmount.round(roundPrecision);
                  //ver 11.5.10.2.10D Chg Start
                  //enteredTaxAmount = round(enteredTaxAmount,roundPrecision);
                  enteredTaxAmount = round(enteredTaxAmount,selectedPrecision);
                  //ver 11.5.10.2.10D Chg End
                  // ���ł̏ꍇ�́A�{�̂̎l�̌ܓ����K�v
                  // �O�ł̏ꍇ�́A�{�̂̎l�̌ܓ��͕s�v�����A���ꂵ�čs��
                  //enteredItemAmount = (Number)enteredItemAmount.round(roundPrecision);
                  //ver 11.5.10.2.10B Del Start
                  //enteredItemAmount = round(enteredItemAmount,roundPrecision);
                  //ver 11.5.10.2.10B Del End
                  //Ver11.5.10.1.4 2005/07/25 Modify End
                }

                //Ver11.5.10.1.3 modify START
                //lineRow.setEnteredItemAmount(enteredItemAmount);            
                //lineRow.setEnteredTaxAmount(enteredTaxAmount);
                //Ver11.5.10.1.3 modify END

                //ver 11.5.10.2.10B Add Start
                // ���ł̏ꍇ
                if (Xx03ArCommonUtil.STR_YES.compareTo(taxFlag) == 0)
                {
                  enteredItemAmount = enteredAmount.subtract(enteredTaxAmount);
                }
                // �O�ł̏ꍇ
                else
                {
                  enteredItemAmount = enteredAmount;
                }
                //ver 11.5.10.2.10B Add End

              } // enteredAmount != null�A�Ōv�Z���x�����u���ׁv
              //Ver11.5.10.1.3 modify START
              // ���͋��z��NULL�łȂ��A���Ōv�Z���x�����u�w�b�_�[�v�̏ꍇ
              else if (enteredAmount != null && Xx03ArCommonUtil.AUTO_TAX_CALC_ON_HEADER.compareTo(autoTaxCalcFlag) == 0)
              {
                //Ver11.5.10.1.6E 2005/12/26 Change Start
//                // �ŗ��擾
//                taxRate = getTaxRate(lineRow.getTaxCode());
                if(headInvDate != null)
                {
//                taxRate = getTaxRate(lineRow.getTaxCode());
                  taxRate = getTaxRate(lineRow.getTaxCode(), headInvDate);
                }
                //Ver11.5.10.1.6E 2005/12/26 Change End
                // ���ł̏ꍇ
                if (Xx03ArCommonUtil.STR_YES.compareTo(taxFlag) == 0)
                {
                  //�L�[�̒�`
                  tableKey = "i" + taxRate.toString();
                  //�n�b�V���e�[�u��headerAmountTable�ɃL�[�Œ�`�����l�����݂��Ȃ��ꍇ
                  if (headerAmountTable.get(tableKey) == null)
                  {
                    headerAmount = enteredAmount;
                  }
                  else //���݂���ꍇ
                  {
                    headerAmount = (Number)enteredAmount.add((Number)headerAmountTable.get(tableKey));
                  }
                  //���v���z�̏���ł��v�Z����
                  headerTaxAmount = headerAmount.multiply(taxRate).divide(taxRate.add(100));
                  // ����ł̒[���������s�Ȃ�
                  // �[�������K�����؂艺���̏ꍇ
                  if (Xx03ArCommonUtil.ROUND_DOWN.compareTo(taxRoundingRule) == 0)
                  {
                    //Ver11.5.10.1.4 2005/07/25 Modify Start
                    //����Ōv�Z���W�b�N�̕ύX
                    //headerTaxAmount = (Number)headerTaxAmount.subtract(Xx03ArCommonUtil.ROUND_NUMBER/roundNumber).round(roundPrecision);
                    //ver 11.5.10.2.10D Chg Start
                    //headerTaxAmount = roundDown(headerTaxAmount,roundNumber);
                    headerTaxAmount = roundDown(headerTaxAmount,selectedPrecision);
                    //ver 11.5.10.2.10D Chg End
                    //Ver11.5.10.1.4 2005/07/25 Modify End
                  }
                  // �[�������K�����؂�グ�̏ꍇ
                  else if (Xx03ArCommonUtil.ROUND_UP.compareTo(taxRoundingRule) == 0)
                  {
                    //Ver11.5.10.1.4 2005/07/25 Modify Start
                    //����Ōv�Z���W�b�N�̕ύX
                    //headerTaxAmount = (Number)headerTaxAmount.add(Xx03ArCommonUtil.ROUND_NUMBER/roundNumber).round(roundPrecision);                
                    //ver 11.5.10.2.10D Chg Start
                    //headerTaxAmount = roundUp(headerTaxAmount,roundNumber);
                    headerTaxAmount = roundUp(headerTaxAmount,selectedPrecision);
                    //ver 11.5.10.2.10D Chg End
                    //Ver11.5.10.1.4 2005/07/25 Modify End
                  }
                  // �[�������K�����l�̌ܓ��̏ꍇ
                  else if (Xx03ArCommonUtil.ROUND.compareTo(taxRoundingRule) == 0)
                  {
                    //Ver11.5.10.1.4 2005/07/25 Modify Start
                    //����Ōv�Z���W�b�N�̕ύX
                    //headerTaxAmount = (Number)headerTaxAmount.round(roundPrecision);
                    //ver 11.5.10.2.10D Chg Start
                    //headerTaxAmount = round(headerTaxAmount,roundPrecision);
                    headerTaxAmount = round(headerTaxAmount,selectedPrecision);
                    //ver 11.5.10.2.10D Chg End
                    //Ver11.5.10.1.4 2005/07/25 Modify End
                  }
                  // �n�b�V���e�[�u���ɍ��v���z��ۑ�
                  headerAmountTable.put(tableKey,headerAmount);

                  // �n�b�V���e�[�u��headerTaxAmountTable�ɏ�Œ�`�����L�[�����l�����݂��Ȃ��ꍇ
                  if (headerTaxAmountTable.get(tableKey) == null)
                  {
                    // ����Ŋz���m�肷��
                    enteredTaxAmount = headerTaxAmount;
                    // ���݂̏���Ŋz��ۑ�
                    headerTaxAmountTable.put(tableKey,headerTaxAmount);
                  }
                  else
                  {
                    // ���v�̏���ł���A�O�ɕۑ���������Ŋz������
                    enteredTaxAmount = (Number)headerTaxAmount.subtract((Number)headerTaxAmountTable.get(tableKey));
                    // ���݂̍��v����Ŋz��ۑ�
                    headerTaxAmountTable.put(tableKey,headerTaxAmount);
                  }
                  // ���ׂ̐Ŕ������z���Z�o
                  enteredItemAmount = enteredAmount.subtract(enteredTaxAmount);
                } //�Ōv�Z���x���u�w�b�_�[�v�A����
                // �O�ł̏ꍇ
                else
                {
                  tableKey = "o" + taxRate.toString();
                  //�n�b�V���e�[�u��headerAmountTable�ɃL�[�Œ�`�����l�����݂��Ȃ��ꍇ
                  if (headerAmountTable.get(tableKey) == null)
                  {
                    headerAmount = enteredAmount;
                  }
                  else //���݂���ꍇ
                  {
                    headerAmount = (Number)enteredAmount.add((Number)headerAmountTable.get(tableKey));
                  }
                  //���v���z�̏���ł��v�Z����
                  headerTaxAmount = headerAmount.multiply(taxRate).divide(100);
                  // ����ł̒[���������s�Ȃ�
                  // �[�������K�����؂艺���̏ꍇ
                  if (Xx03ArCommonUtil.ROUND_DOWN.compareTo(taxRoundingRule) == 0)
                  {
                    //Ver11.5.10.1.4 2005/07/25 Modify Start
                    //����Ōv�Z���W�b�N�̕ύX
                    //headerTaxAmount = (Number)headerTaxAmount.subtract(Xx03ArCommonUtil.ROUND_NUMBER/roundNumber).round(roundPrecision);
                    //ver 11.5.10.2.10D Chg Start
                    //headerTaxAmount = roundDown(headerTaxAmount,roundNumber);
                    headerTaxAmount = roundDown(headerTaxAmount,selectedPrecision);
                    //ver 11.5.10.2.10D Chg End
                    //Ver11.5.10.1.4 2005/07/25 Modify End
                  }
                  // �[�������K�����؂�グ�̏ꍇ
                  else if (Xx03ArCommonUtil.ROUND_UP.compareTo(taxRoundingRule) == 0)
                  {
                    //Ver11.5.10.1.4 2005/07/25 Modify Start
                    //����Ōv�Z���W�b�N�̕ύX
                    //headerTaxAmount = (Number)headerTaxAmount.add(Xx03ArCommonUtil.ROUND_NUMBER/roundNumber).round(roundPrecision);                
                    //ver 11.5.10.2.10D Chg Start
                    //headerTaxAmount = roundUp(headerTaxAmount,roundNumber);
                    headerTaxAmount = roundUp(headerTaxAmount,selectedPrecision);
                    //ver 11.5.10.2.10D Chg End
                    //Ver11.5.10.1.4 2005/07/25 Modify End
                  }
                  // �[�������K�����l�̌ܓ��̏ꍇ
                  else if (Xx03ArCommonUtil.ROUND.compareTo(taxRoundingRule) == 0)
                  {
                    //Ver11.5.10.1.4 2005/07/25 Modify Start
                    //����Ōv�Z���W�b�N�̕ύX
                    //headerTaxAmount = (Number)headerTaxAmount.round(roundPrecision);
                    //ver 11.5.10.2.10D Chg Start
                    //headerTaxAmount = round(headerTaxAmount,roundPrecision);
                    headerTaxAmount = round(headerTaxAmount,selectedPrecision);
                    //ver 11.5.10.2.10D Chg End
                    //Ver11.5.10.1.4 2005/07/25 Modify End
                  }
                  // �n�b�V���e�[�u���ɍ��v���z��ۑ�
                  headerAmountTable.put(tableKey,headerAmount);

                  // �n�b�V���e�[�u��headerTaxAmountTable�ɏ�Œ�`�����L�[�����l�����݂��Ȃ��ꍇ
                  if (headerTaxAmountTable.get(tableKey) == null)
                  {
                    // ����Ŋz���m�肷��
                    enteredTaxAmount = headerTaxAmount;
                    // ���݂̏���Ŋz��ۑ�
                    headerTaxAmountTable.put(tableKey,headerTaxAmount);
                  }
                  else
                  {
                    // ���v�̏���ł���A�O�ɕۑ���������Ŋz������
                    enteredTaxAmount = (Number)headerTaxAmount.subtract((Number)headerTaxAmountTable.get(tableKey));
                    // ���݂̍��v����Ŋz��ۑ�
                    headerTaxAmountTable.put(tableKey,headerTaxAmount);
                  }
                  // ���ׂ̐Ŕ������z
                  enteredItemAmount = enteredAmount;
                  
                } //�Ōv�Z���x���u�w�b�_�[�v�A�O��
              } // ���͋��z��NULL�łȂ��A���Ōv�Z���x���u�w�b�_�[�v
              //�m�肵������ŁA�Ŕ������z��lineRow�ɖ߂�
              lineRow.setEnteredItemAmount(enteredItemAmount);
              lineRow.setEnteredTaxAmount(enteredTaxAmount);
              //Ver11.5.10.1.3 modify END
            } // �P���A���ʁA�ŋ敪����
          } // lineRow != null
        } // for loop

        //Ver11.5.10.1.3 DELETE START
        //// *************************************************************************
        //// * ����ł̒���
        //// *************************************************************************
        //// �O�ł̖��ׂ����݂���A�������v�Z�̌v�Z���x�����w�b�_�[�̏ꍇ
        //if ((isExistExcludingTax) && (Xx03ArCommonUtil.AUTO_TAX_CALC_ON_HEADER.compareTo(autoTaxCalcFlag) == 0))
        //{
        //  // �O�ł̖��ׂ̓��͋��z(�{�̋��z)�𑫂����񂾊z�ɑ΂��āA����Ōv�Z�A�[���������s��
        //  autoEnteredTaxAmountExTax = enteredAmountExTax.multiply(taxRate).divide(100);

        //  // �[�������K�����؂艺���̏ꍇ
        //  if (Xx03ArCommonUtil.ROUND_DOWN.compareTo(taxRoundingRule) == 0)
        //  {
        //     autoEnteredTaxAmountExTax = (Number)autoEnteredTaxAmountExTax.subtract(Xx03ArCommonUtil.ROUND_NUMBER/roundNumber).round(roundPrecision);
        //  }
        //  // �[�������K�����؂�グ�̏ꍇ
        //  else if (Xx03ArCommonUtil.ROUND_UP.compareTo(taxRoundingRule) == 0)
        //  {
        //    autoEnteredTaxAmountExTax = (Number)autoEnteredTaxAmountExTax.add(Xx03ArCommonUtil.ROUND_NUMBER/roundNumber).round(roundPrecision);                
        //  }
        //  // �l�̌ܓ�(�����)�Ȃ̂ŁA�l�̌ܓ�(�����) : round
        //  else if (Xx03ArCommonUtil.ROUND.compareTo(taxRoundingRule) == 0)
        // {
        //    autoEnteredTaxAmountExTax = (Number)autoEnteredTaxAmountExTax.round(roundPrecision);
        //  }

        //  // �d�󃌃x���̏���Ŋz�Ɩ��׃��x���̏���Ŋz���r
        //  coordinateValue = autoEnteredTaxAmountExTax.subtract(enteredTaxAmountExTax);

        //  if (coordinateValue.compareTo(0) != 0)
        //  {
        //    lineRow = (Xx03ReceivableSlipsLineVORowImpl)selectLineIter.getRowAtRangeIndex(coordinateId);
        //    lineRow.setEnteredTaxAmount(lineRow.getEnteredTaxAmount().add(coordinateValue));
        //  }
        //}
        //Ver11.5.10.1.3 DELETE END
      // ver1.3 change end --------------------------------------------------------
      } // fetchedLineRowCount > 0

    //Ver11.5.10.1.6K 2006/01/19 Add Start
    }
    //Ver11.5.10.1.6K 2006/01/19 Add End

      // �I������
      endProcedure(getClass().getName(), methodName);
    }
    finally
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator(); 
      }
      if(selectLineIter != null)
      {
        selectLineIter.closeRowSetIterator();
      }
    }

    //Ver11.5.10.1.6K 2006/01/19 Add Start
    return retVec;
    //Ver11.5.10.1.6K 2006/01/19 Add End

  } // resetTaxAmount()

  /**
   * �ŗ��̎擾
   * @param taxCode �ŃR�[�h
   * @return Number �ŗ�
   */
  //Ver11.5.10.1.6E 2005/12/26 Change Start
//  private Number getTaxRate(String taxCode)
  private Number getTaxRate(String taxCode,Date GlDate)
  //Ver11.5.10.1.6E 2005/12/26 Change End
  {
    Number retNum = null;
    
    // �r���[�E�I�u�W�F�N�g�̎擾
    Xx03TaxCodesLovVOImpl vo = getXx03TaxCodesLovVO1();

    //Ver11.5.10.1.6E 2005/12/26 Change Start
//    vo.initQuery(taxCode);
    vo.initQuery(taxCode, GlDate);
    //Ver11.5.10.1.6E 2005/12/26 Change End

    vo.first();

    Xx03TaxCodesLovVORowImpl row = (Xx03TaxCodesLovVORowImpl)vo.getCurrentRow();

    if (row != null)
    {
      retNum = row.getTaxRate();
    }

    if (retNum == null)
    {
      throw new OAException("XX03",
                            "APP-XX03-08035",
                            null,
                            OAException.ERROR,
                            null);
    }
    
    return retNum;
  }

  /**
   * �ύX����(�S��)
   * @param �Ȃ�
   * @return �ύX�����������ǂ���
   */
  public boolean isDirty()
  {
    // ����������
    String methodName = "isDirty";
    startProcedure(getClass().getName(), methodName);
    
    // �I������
    endProcedure(getClass().getName(), methodName);
    return getTransaction().isDirty();
  }

  /**
   * ���z�̍Čv�Z
   * @param �Ȃ�
   * @return �Ȃ�
   */
  public void recalculate()
  {
    String methodName = "recalculate";
    startProcedure(getClass().getName(), methodName); 

    // ���͋��z�Z�o
    calculateInput();

    // ���͋��z�A�{�̋��z�A����Ŋz�A���Z�ϋ��z�̎Z�o
    int coordinateId = resetAmount();

    // ���v���z�̎Z�o
    resetTotalAmount();

    // ���Z�ϋ��z�̒���
    OAViewObject headerVo = getXx03ReceivableSlipsVO1();
    RowSetIterator selectHeaderIter = null;    
    int fetchedHeaderRowCount;
    int fetchedLineRowCount;

    try
    {
      Xx03ReceivableSlipsVORowImpl headerRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedHeaderRowCount = headerVo.getFetchedRowCount();
      fetchedHeaderRowCount = headerVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectHeaderIter = headerVo.createRowSetIterator("selectHeaderIter");

      if (fetchedHeaderRowCount > 0)
      {
        selectHeaderIter.setRangeStart(0);
        selectHeaderIter.setRangeSize(fetchedHeaderRowCount);
        headerRow = (Xx03ReceivableSlipsVORowImpl)selectHeaderIter.first();

        if (headerRow != null){
          // Validation
          headerRow.validate();
        } // headerRow
      } // fetchedHeaderRocCount
      // �I������
      endProcedure(getClass().getName(), methodName);
    }
    finally
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();
      }
    }
  }

  /**
   * �蓮�ł�Validation�`�F�b�N
   * @param �Ȃ�
   * @return 
   */
  //ver11.5.10.1.6 Chg Start
//  public void checkSelfValidation()
  public Vector checkSelfValidation()
  //ver11.5.10.1.6 Chg End
  {
    // ����������
    String methodName = "checkSelfValidation";
    startProcedure(getClass().getName(), methodName);

    //ver11.5.10.1.6 Add Start
    Vector msg = new Vector();
    //ver11.5.10.1.6 Add End

    RowSetIterator selectHeaderIter = null;
    RowSetIterator selectLineIter = null;

    //ver11.5.10.1.6 Chg Start
//    int fetchedHeaderRowCount;
//    int fetchedLineRowCount;
    int getHeaderRowCount;
    int getLineRowCount;
    //ver11.5.10.1.6 Chg End

    //ver 11.5.10.1.6I Add Start
    RowSetIterator selectSlipIter = null;    
    int getSlipRowCount;
    //ver 11.5.10.1.6I Add End

    try
    {
      // �r���[�E�I�u�W�F�N�g�̎擾
      OAViewObject headerVo = getXx03ReceivableSlipsVO1();
      OAViewObject lineVo = getXx03ReceivableSlipsLineVO1();

      Xx03ReceivableSlipsVORowImpl headerRow = null;

      //ver11.5.10.1.6 Chg Start
      //fetchedHeaderRowCount = headerVo.getFetchedRowCount();
      getHeaderRowCount = headerVo.getRowCount();
      //ver11.5.10.1.6 Chg End

      selectHeaderIter = headerVo.createRowSetIterator("selectHeaderIter");

      Xx03ReceivableSlipsLineVORowImpl lineRow = null;

      //ver11.5.10.1.6 Chg Start
      //fetchedLineRowCount = lineVo.getFetchedRowCount();
      getLineRowCount = lineVo.getRowCount();
      //ver11.5.10.1.6 Chg End

      selectLineIter = lineVo.createRowSetIterator("selectLineIter");

      //ver 11.5.10.1.6I Add Start
      OAViewObject slipVo  = getXx03SlipTypesLovVO1();
      Xx03SlipTypesLovVORowImpl slipRow  = null;
      getSlipRowCount  = slipVo.getRowCount();
      selectSlipIter  = slipVo.createRowSetIterator("selectSlipIter");
      //ver 11.5.10.1.6I Add End

      //ver 11.5.10.1.6I Chg Start
      ////ver11.5.10.1.6 Chg Start
      ////if (fetchedHeaderRowCount > 0)
      //if (getHeaderRowCount > 0)
      ////ver11.5.10.1.6 Chg End
      if ((getHeaderRowCount > 0) && (getSlipRowCount > 0))
      //ver 11.5.10.1.6I Chg End
      {
        selectHeaderIter.setRangeStart(0);
        //ver11.5.10.1.6 Chg Start
        //selectHeaderIter.setRangeSize(fetchedHeaderRowCount);
        selectHeaderIter.setRangeSize(getHeaderRowCount);
        //ver11.5.10.1.6 Chg End

        headerRow = (Xx03ReceivableSlipsVORowImpl)selectHeaderIter.first();

        //ver 11.5.10.1.6I Add Start
        selectSlipIter.setRangeStart(0);
        selectSlipIter.setRangeSize(getSlipRowCount);
        slipRow = (Xx03SlipTypesLovVORowImpl)selectSlipIter.first();
        //ver 11.5.10.1.6I Add End

        //ver 11.5.10.1.6I Chg Start
        //if (headerRow != null){
        if ((headerRow != null) && (slipRow != null))
        {
        //ver 11.5.10.1.6I Chg End
          // Validation
          //ver11.5.10.1.6 Add Start
          //headerRow.validate();
          // �`�F�b�N�Ώ�
          //ver 11.5.10.1.6I Chg Start
          //msg = (Vector)validateHeader( msg
          //                             ,methodName
          //                             ,headerRow.getReceivableNum()       // �`�[�ԍ�
          //                             ,headerRow.getSlipType()            // �`�[��ʃR�[�h
          //                             ,headerRow.getTransTypeId()         // ����h�c
          //                             ,headerRow.getCustomerId()          // �ڋq�h�c
          //                             ,headerRow.getCustomerOfficeId()    // �ڋq���Ə��h�c
          //                             ,headerRow.getReceiptMethodId()     // �x�����@�h�c
          //                             ,headerRow.getTermsId()             // �x�������h�c
          //                             ,headerRow.getInvoiceCurrencyCode() // �ʉ݃R�[�h
          //                             ,headerRow.getInvoiceDate()         // ���������t
          //                             ,headerRow.getOrigInvoiceNum()      // �C�����`�[�ԍ�
          //                             );
          msg = (Vector)validateHeader( msg
                                       ,methodName
                                       ,headerRow.getReceivableNum()       // �`�[�ԍ�
                                       ,headerRow.getSlipType()            // �`�[��ʃR�[�h
                                       ,headerRow.getTransTypeId()         // ����h�c
                                       ,headerRow.getCustomerId()          // �ڋq�h�c
                                       ,headerRow.getCustomerOfficeId()    // �ڋq���Ə��h�c
                                       ,headerRow.getReceiptMethodId()     // �x�����@�h�c
                                       ,headerRow.getTermsId()             // �x�������h�c
                                       ,headerRow.getInvoiceCurrencyCode() // �ʉ݃R�[�h
                                       ,headerRow.getInvoiceDate()         // ���������t
                                       ,headerRow.getOrigInvoiceNum()      // �C�����`�[�ԍ�
                                       ,headerRow.getWfStatus()            // ���[�N�t���[�X�e�[�^�X
                                       ,headerRow.getApproverPersonId()    // ���F�҂h�c
                                       ,slipRow.getAttribute14()           // �`�[��ʃA�v��
                                       );
          //ver 11.5.10.1.6I Chg End
          //ver11.5.10.1.6 Add End
        } // headerRow
      } // getHeaderRocCount
      //ver 11.5.10.1.6I Chg Start
      //else
      else if (!(getHeaderRowCount > 0))
      //ver 11.5.10.1.6I Chg End
      {
        // �G���[�E���b�Z�[�W
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);        
      } // getHeaderRowCount
      //ver 11.5.10.1.6I Add Start
      else if (!(getSlipRowCount > 0))
      {
        // �G���[�E���b�Z�[�W
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03SlipTypesLovVO1")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);        
      } // updRowCount
      //ver 11.5.10.1.6I Add End

      //ver11.5.10.1.6 Chg Start
      //if (fetchedLineRowCount > 0)
      if (getLineRowCount > 0)
      //ver11.5.10.1.6 Chg End
      {
        selectLineIter.setRangeStart(0);
        //ver11.5.10.1.6 Chg Start
        //selectLineIter.setRangeSize(fetchedLineRowCount);
        selectLineIter.setRangeSize(getLineRowCount);
        //ver11.5.10.1.6 Chg End

        //ver11.5.10.1.6 Chg Start
        //for (int i=0; i<fetchedLineRowCount; i++)
        for (int i=0; i<getLineRowCount; i++)
        //ver11.5.10.1.6 Chg End
        {
          lineRow = (Xx03ReceivableSlipsLineVORowImpl)selectLineIter.getRowAtRangeIndex(i);

          if (lineRow != null)
          {
            // Validation
            //ver11.5.10.1.6 Chg Start
            //lineRow.validate();


            //Ver11.5.10.1.6E 2005/12/26 Change Start
            //msg = (Vector)validateLine( msg
            //                           ,i
            //                           ,methodName
            //                           ,headerRow.getReceivableNum()       // �`�[�ԍ�
            //                           ,headerRow.getSlipType()            // �`�[��ʃR�[�h
            //                           ,headerRow.getInvoiceDate()         // ���������t
            //                           ,lineRow.getSlipLineType()          // �������e�h�c
            //                           ,lineRow.getSlipLineUom()           // �P��
            //                           );
            msg = (Vector)validateLine( msg
                                       ,i
                                       ,methodName
                                       ,headerRow.getReceivableNum()       // �`�[�ԍ�
                                       //ver 11.5.10.1.6Q Del Start
                                       //,headerRow.getSlipType()            // �`�[��ʃR�[�h
                                       //ver 11.5.10.1.6Q Del End
                                       ,headerRow.getInvoiceDate()         // ���������t
                                       //ver 11.5.10.1.6Q Del Start
                                       //,lineRow.getSlipLineType()          // �������e�h�c
                                       //ver 11.5.10.1.6Q Del End
                                       ,lineRow.getSlipLineUom()           // �P��
                                       ,lineRow.getTaxName()
                                       ,lineRow.getTaxCode()
                                       //Ver11.5.10.1.6P Add Start
                                       ,lineRow.getTaxId()
                                       //Ver11.5.10.1.6P Add End
                                       //Ver11.5.10.1.6R Add Start
                                       ,lineRow.getAmountIncludesTaxFlag()
                                       //Ver11.5.10.1.6R Add End
                                       );
            //Ver11.5.10.1.6E 2005/12/26 Change End
            //ver11.5.10.1.6 Chg End
          } // lineRow != null
        } // for loop
      } // getLineRowCount > 0

      // �I������
      endProcedure(getClass().getName(), methodName);
    }
    //ver 11.5.10.1.6Q Add Start
    catch (OAException oaEx)
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();
      }
      if(selectLineIter != null)
      {
        selectLineIter.closeRowSetIterator();
      }
      if(selectSlipIter != null)
      {
        selectSlipIter.closeRowSetIterator();
      }
      throw new OAException(oaEx.getMessage());
    }
    //ver 11.5.10.1.6Q Add End
    //ver 11.5.10.1.6Q Chg Start
    //finally
    //{
    //  if(selectHeaderIter != null)
    //  {
    //    selectHeaderIter.closeRowSetIterator();
    //  }
    //  if(selectLineIter != null)
    //  {
    //    selectLineIter.closeRowSetIterator();
    //  }
    //  //ver11.5.10.1.6 Add Start
    //  return msg;
    //  //ver11.5.10.1.6 Add End
    //}
    selectHeaderIter.closeRowSetIterator();
    selectLineIter.closeRowSetIterator();
    selectSlipIter.closeRowSetIterator();
    return msg;
    //ver 11.5.10.1.6Q Chg End
  } // resetAmount()

  /**
   * �{�̋��z�̎Z�o�A���Z�ϋ��z�̎Z�o
   * @param �Ȃ�
   * @return 
   */
  private int resetAmount()
  {
    // ����������
    String methodName = "resetAmount";
    startProcedure(getClass().getName(), methodName);

    Number enteredAmount = new Number(0);     // ���͋��z
    Number enteredTaxAmount = new Number(0);  // ����Ŋz
    String taxFlag = null;                    // ���Ńt���O
    String taxCode = null;                    // �ŋ敪
    Number enteredItemAmount = new Number(0); // �{�̋��z
    Number accountedAmount = new Number(0);   // ���Z�ϋ��z
    String invoiceCurrencyCode = null;        // �ʉ�
    Number exchangeRate = new Number(0);      // ���[�g
    String currencyCode = null;               // �@�\�ʉ�
    Number precision = new Number(0);         // �@�\�ʉ݂̐��x

    RowSetIterator selectHeaderIter = null;    
    RowSetIterator selectLineIter = null;
    int fetchedHeaderRowCount;
    int fetchedLineRowCount;

    //Ver11.5.10.1.6E 2005/12/26 Add Start
    Date headInvDate = null;
    //Ver11.5.10.1.6E 2005/12/26 Add End

    try
    {
      Number maxAccountedAmount = new Number(0);                    // �����Ώۂ̎ؕ����Z�ϋ��z
      int coordinateId = new Integer(Integer.MAX_VALUE).intValue(); // �����Ώۂ̎ؕ�VO
    
      // �r���[�E�I�u�W�F�N�g�̎擾
      OAViewObject headerVo = getXx03ReceivableSlipsVO1();
      OAViewObject lineVo = getXx03ReceivableSlipsLineVO1();

      Xx03ReceivableSlipsVORowImpl headerRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedHeaderRowCount = headerVo.getFetchedRowCount();
      fetchedHeaderRowCount = headerVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectHeaderIter = headerVo.createRowSetIterator("selectHeaderIter");

      Xx03ReceivableSlipsLineVORowImpl lineRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedLineRowCount = lineVo.getFetchedRowCount();
      fetchedLineRowCount = lineVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectLineIter = lineVo.createRowSetIterator("selectLineIter");

      // �@�\�ʉ݂̎擾
      currencyCode = getCurrencyCode();
      
      // �@�\�ʉ݂̐��x���擾
      precision = getPrecision();

      if (fetchedHeaderRowCount > 0)
      {
        selectHeaderIter.setRangeStart(0);
        selectHeaderIter.setRangeSize(fetchedHeaderRowCount);

        headerRow = (Xx03ReceivableSlipsVORowImpl)selectHeaderIter.first();

        if (headerRow != null){
          // �ʉݎ擾
          // ���؏�����EO�ɂĎ��s
          invoiceCurrencyCode = headerRow.getInvoiceCurrencyCode();
          if ( invoiceCurrencyCode == null )
          {
            // �ʉݖ�����
            // �G���[�E���b�Z�[�W
            MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
            throw new OAException("XX03", "APP-XX03-13017", tokens);        
          }
      
          // ���[�g�擾
          exchangeRate = headerRow.getExchangeRate();

          //Ver11.5.10.1.6E 2005/12/26 Add Start
          headInvDate = headerRow.getInvoiceDate();
          //Ver11.5.10.1.6E 2005/12/26 Add End

        } // headerRow
      } // fetchedHeaderRocCount
      else
      {
        // �G���[�E���b�Z�[�W
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);        
      } // fetchedHeaderRowCount

      if (fetchedLineRowCount > 0)
      {
        selectLineIter.setRangeStart(0);
        selectLineIter.setRangeSize(fetchedLineRowCount);

        for (int i=0; i<fetchedLineRowCount; i++)
        {
          lineRow = (Xx03ReceivableSlipsLineVORowImpl)selectLineIter.getRowAtRangeIndex(i);

          if (lineRow != null)
          {
            if ((lineRow.getSlipLineUnitPrice() != null)
                && (lineRow.getSlipLineQuantity() != null)
                && (lineRow.getTaxCode() != null))
            {
              // *********************************************************************
              // * �{�̋��z�̎Z�o
              // *********************************************************************
              // ���͋��z�擾
              enteredAmount = lineRow.getSlipLineEnteredAmount();

              // ����ŋ��z�擾
              enteredTaxAmount = lineRow.getEnteredTaxAmount();

              // �ŋ敪�擾
              taxCode = lineRow.getTaxCode();

              // ���Z�ϋ��z�̎擾
              accountedAmount = lineRow.getAccountedAmount();

              // ���Ńt���O�擾
// ver 1.2 Change Start ���Ńt���O��ŋ敪����擾����悤�ύX
//              taxFlag = lineRow.getAmountIncludesTaxFlag();

              //Ver11.5.10.1.6E 2005/12/26 Change Start
//              taxFlag = getIncludesTaxFlag(taxCode);
              if(headInvDate != null)
              {
                taxFlag = getIncludesTaxFlag(taxCode, headInvDate);
              }
              //Ver11.5.10.1.6E 2005/12/26 Change End

// ver 1.2 Change End

              if ((enteredAmount != null) && (enteredTaxAmount != null))
              {
                // ���ł̏ꍇ
                if (Xx03ArCommonUtil.STR_YES.compareTo(taxFlag) == 0)
                {
                  enteredItemAmount = enteredAmount.subtract(enteredTaxAmount);    
                }
                // �O�ł̏ꍇ
                else
                {
                  enteredItemAmount = enteredAmount;    
                }
                lineRow.setEnteredItemAmount(enteredItemAmount);            

                // *******************************************************************
                // * ���Z�ϋ��z�̎Z�o
                // *******************************************************************
                if (currencyCode.compareTo(invoiceCurrencyCode) == 0)
                {
                  // �@�\�ʉ݂̏ꍇ
                  accountedAmount = enteredItemAmount.add(enteredTaxAmount);            
                }
                else{
                  // �O�݂̏ꍇ
                  // �@�\�ʉ݂̐��x�Ŏl�̌ܓ�
                  if ( exchangeRate != null )
                  {
                    // ���[�g���͂���
                    accountedAmount = (Number)enteredItemAmount.add(enteredTaxAmount).multiply(exchangeRate).round(precision.intValue());
                  }
                  else{
                    // ���[�g������
                    // �G���[�E���b�Z�[�W
                    MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
                    throw new OAException("XX03", "APP-XX03-13040", tokens);        
                  }

                  // �����Ώۂ̎ؕ����Z�ϋ��z�AID��ێ�
                  if (maxAccountedAmount.compareTo((Number)accountedAmount.abs()) <= 0)
                  {
                    maxAccountedAmount = accountedAmount;
                    coordinateId = i;
                  }
                }
                lineRow.setAccountedAmount(accountedAmount);
              } // enteredAmountDr != null        
            } // �P���A���ʁA�ŋ敪������
          } // lineRow != null
        } // for loop
      } // fetchedLineRowCount > 0

      // �I������
      endProcedure(getClass().getName(), methodName);

      return coordinateId;
    }
    finally
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();
      }
      if(selectLineIter != null)
      {
        selectLineIter.closeRowSetIterator();
      }
    }
  } // resetAmount()

  /**
   * ���v���z�̎Z�o
   * @param �Ȃ�
   * @return �Ȃ�
   */
  private void resetTotalAmount()
  {
    // ����������
    String methodName = "resetTotalAmount";
    startProcedure(getClass().getName(), methodName);

    Number totalItemEntered = new Number(0);  // �{�̍��v���z
    Number totalTaxEntered = new Number(0);   // ����ō��v���z
    Number totalEntered = new Number(0);      // ���v���z(�{��+�����)
    Number totalAccounted = new Number(0);    // ���Z�ύ��v���z

    RowSetIterator selectHeaderIter = null;    
    RowSetIterator selectLineIter = null;
    int fetchedHeaderRowCount;
    int fetchedLineRowCount;

    try
    {
      // �r���[�E�I�u�W�F�N�g�̎擾
      OAViewObject headerVo = getXx03ReceivableSlipsVO1();
      OAViewObject lineVo = getXx03ReceivableSlipsLineVO1();

      if (headerVo == null)
      {
        // �G���[�E���b�Z�[�W
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13035", tokens);
      }

      if (lineVo == null)
      {
        // �G���[�E���b�Z�[�W
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsLineVO1")};
        throw new OAException("XX03", "APP-XX03-13035", tokens);
      }
    
      Xx03ReceivableSlipsVORowImpl headerRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedHeaderRowCount = headerVo.getFetchedRowCount();
      fetchedHeaderRowCount = headerVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectHeaderIter = headerVo.createRowSetIterator("selectHeaderIter");

      Xx03ReceivableSlipsLineVORowImpl lineRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedLineRowCount = lineVo.getFetchedRowCount();
      fetchedLineRowCount = lineVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectLineIter = lineVo.createRowSetIterator("selectLineIter");

      if (fetchedHeaderRowCount > 0)
      {
        selectHeaderIter.setRangeStart(0);
        selectHeaderIter.setRangeSize(fetchedHeaderRowCount);

        headerRow = (Xx03ReceivableSlipsVORowImpl)selectHeaderIter.first();
      } // fetchedHeaderRocCount
      else
      {
        // �G���[�E���b�Z�[�W
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);        
      } // fetchedHeaderRowCount

      if (fetchedLineRowCount > 0)
      {
        selectLineIter.setRangeStart(0);
        selectLineIter.setRangeSize(fetchedLineRowCount);

        for (int i=0; i<fetchedLineRowCount; i++)
        {
          lineRow = (Xx03ReceivableSlipsLineVORowImpl)selectLineIter.getRowAtRangeIndex(i);

          if ((lineRow != null) &&
              ((lineRow.getSlipLineTypeName() != null) && 
               (!"".equals(lineRow.getSlipLineTypeName()))) &&
              (lineRow.getSlipLineUnitPrice() != null) &&
              (lineRow.getSlipLineQuantity() != null) &&
              (lineRow.getTaxCode() != null))
          {
            // *********************************************************************
            // * ���v���z�̎Z�o
            // *********************************************************************
            totalItemEntered = totalItemEntered.add(lineRow.getEnteredItemAmount());
            totalTaxEntered = totalTaxEntered.add(lineRow.getEnteredTaxAmount());
            totalEntered = totalItemEntered.add(totalTaxEntered);
            totalAccounted = totalAccounted.add(lineRow.getAccountedAmount());
          } // lineRow != null        
        } // for loop

        // �[�����z�Z�o
        Number commitmentAmount = new Number(0);
        // �[���`�[�ԍ����w�肳��Ă���ꍇ
        if (headerRow.getCommitmentNumber() != null)
        {
          // �{�̋��z�{����Ŋz�����[���c�� �� �[�����z���[���c��
          if (((totalItemEntered.add(totalTaxEntered)).compareTo(headerRow.getCommitmentAmount())) >= 0)
          {
            commitmentAmount = headerRow.getCommitmentAmount();
          }
          // �{�̋��z�{����Ŋz���[���c��   �� �[�����z���{�̋��z�{����Ŋz
          else
          {
            commitmentAmount = totalItemEntered.add(totalTaxEntered);
          }
        }
        // �������z���{�̋��z�{����Ŋz�|�[�����z
        totalEntered = new Number(totalEntered.sub(commitmentAmount));

        headerRow.setInvItemAmount(totalItemEntered);
        headerRow.setInvTaxAmount(totalTaxEntered);
        headerRow.setInvAmount(totalEntered);
        headerRow.setInvAccountedAmount(totalAccounted);
        headerRow.setInvPrepayAmount(commitmentAmount);
      } // fetchedLineRowCount > 0

      // �I������
      endProcedure(getClass().getName(), methodName);
    }
    finally
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();
      }
      if(selectLineIter != null)
      {
        selectLineIter.closeRowSetIterator();
      }
    }
  } // resetTotalAmount()

  /**
   * �@�\�ʉ݂̐��x�̎擾
   * @param
   * @return Number ���x
   */
  private Number getPrecision()
  {
    // ����������
    String methodName = "getPrecision";
    startProcedure(getClass().getName(), methodName);
    
    // �r���[�E�I�u�W�F�N�g�̎擾
    Xx03PrecisionVOImpl vo = getXx03PrecisionVO1();
    vo.executeQuery();
    vo.first();

    Xx03PrecisionVORowImpl row = (Xx03PrecisionVORowImpl)vo.getCurrentRow();

    // �I������
    endProcedure(getClass().getName(), methodName);

    return row.getPrecision();
  }

  // ver1.3 add start ---------------------------------------------------------
  /**
   * ��ʂőI�����ꂽ�ʉ݂̐��x�̎擾
   * @param String �ʉ݃R�[�h
   * @return Number ���x
   */
  private Number getSelectedPrecision(String currencyCode)
  {
    // ����������
    String methodName = "getSelectedPrecision";
    startProcedure(getClass().getName(), methodName);
    
    // �r���[�E�I�u�W�F�N�g�̎擾
    Xx03SelectedPrecisionVOImpl vo = getXx03SelectedPrecisionVO1();
    vo.initQuery(currencyCode);
    vo.first();

    Xx03SelectedPrecisionVORowImpl row = (Xx03SelectedPrecisionVORowImpl)vo.getCurrentRow();

    // �I������
    endProcedure(getClass().getName(), methodName);

    return row.getPrecision();
  }
  // ver1.3 add end -----------------------------------------------------------

  /**
   * ���Z�ϋ��z�̒���
   * @param headerRow �w�b�_�s�I�u�W�F�N�g
   * @param coordinateId �����Ώۍs�ԍ�
   * @return �Ȃ�
   */
  public void resetAccountedAmount(Xx03ReceivableSlipsVORowImpl headerRow, int coordinateId)
  {
    // ����������
    String methodName = "resetAccountedAmount";
    startProcedure(getClass().getName(), methodName);

    Number coordinateValue = new Number(0);           // ���Z�ϋ��z�̒����z
    Number totalAccounted = new Number(0);            // �������̊��Z�ύ��v���z
    Number maxAccountedAmount = new Number(0);        // �������̊��Z�ϋ��z
    Number absMaxAccountedAmount = new Number(0);     // �������̊��Z�ϋ��z(��Βl)

    int fetchedLineRowCount = 0;
    RowSetIterator selectLineIter = null;   
    Xx03ReceivableSlipsLineVORowImpl lineRow = null;

     try
     {
      // �r���[�E�I�u�W�F�N�g�̎擾
      OAViewObject lineVo = getXx03ReceivableSlipsLineVO1();
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedLineRowCount = lineVo.getFetchedRowCount();    
      fetchedLineRowCount = lineVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectLineIter = lineVo.createRowSetIterator("selectLineIter");

      if (fetchedLineRowCount > 0)
      {
        selectLineIter.setRangeStart(0);
        selectLineIter.setRangeSize(fetchedLineRowCount);
      }
      else
      {
        // �G���[�E���b�Z�[�W
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsLineVO1")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);              
      }

      lineRow = (Xx03ReceivableSlipsLineVORowImpl)selectLineIter.getRowAtRangeIndex(coordinateId);

      // �����z�̎Z�o
      coordinateValue = headerRow.getInvAccountedAmount().subtract(headerRow.getInvAmount());

      // �������̊��Z�ύ��v���z���Z�o
      totalAccounted = headerRow.getInvAccountedAmount();

      // �������̊��Z�ϋ��z�̐�Βl���Z�o
      maxAccountedAmount = lineRow.getAccountedAmount();
      absMaxAccountedAmount = (Number)maxAccountedAmount.abs();

      // ����
      if (coordinateValue.compareTo(0) != 0)
      {
        headerRow.setInvAccountedAmount(totalAccounted.subtract(coordinateValue));
        lineRow.setAccountedAmount(maxAccountedAmount.subtract(coordinateValue));  
      }

      // �I������
      endProcedure(getClass().getName(), methodName);
    }
    finally
    {
      if(selectLineIter != null)
      {
        selectLineIter.closeRowSetIterator();
      }
    }
  } // resetAccountedAmount()

  /**
   * �`�[�ԍ��̍̔�
   * @param num_type ��/���敪
   * @param requestEnableFlag �\���\�t���O
   * @return �Ȃ�
   */
  public void publishNum(String num_type, String requestEnableFlag)
  {
    // ����������
    String methodName = "publishNum";
    startProcedure(getClass().getName(), methodName);  

    Number receivableNum = new Number(0);    // �`�[�ԍ�
    
    RowSetIterator selectHeaderIter = null;
    int fetchedHeaderRowCount;

     try
     {
      // �r���[�E�I�u�W�F�N�g�̎擾
      OAViewObject headerVo = getXx03ReceivableSlipsVO1();
      //ver 11.5.10.2.7 Chg Start
      //Xx03SlipNumbersVOImpl slipNumVo = getXx03SlipNumbersVO1();
      Xx03SlipNumbersVOImpl slipNumVo = null;
      //ver 11.5.10.2.7 Chg End
     
      Xx03ReceivableSlipsVORowImpl headerRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedHeaderRowCount = headerVo.getFetchedRowCount();
      fetchedHeaderRowCount = headerVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectHeaderIter = headerVo.createRowSetIterator("selectHeaderIter");

      if (fetchedHeaderRowCount > 0)
      {
        selectHeaderIter.setRangeStart(0);
        selectHeaderIter.setRangeSize(fetchedHeaderRowCount);

        headerRow = (Xx03ReceivableSlipsVORowImpl)selectHeaderIter.first();
      } // fetchedHeaderRocCount
      else
      {
        // �G���[�E���b�Z�[�W
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);
      } // fetchedHeaderRowCount

      Xx03SlipNumbersVORowImpl slipNumRow = null;

      //ver 11.5.10.2.7 Mov Start
      //�����̃^�C�~���O�����b�N�Ƌ߂Â��邽�߈ړ�
      ////Ver11.5.10.2.6C ADD Start
      //// ���ԍ��̐ړ�����VO����擾����
      //slipNumVo.initQuery(Xx03ArCommonUtil.TEMP_SLIP_NUM_TYPE);
      //slipNumVo.first();
      //slipNumRow = (Xx03SlipNumbersVORowImpl)slipNumVo.getCurrentRow();
      //String tempCode = slipNumRow.getTemporaryCode();
      ////Ver11.5.10.2.6C ADD End
      //ver 11.5.10.2.7 Mov End

      // �ۑ����̉��`�[�ԍ��̍̔�
      if (Xx03ArCommonUtil.TEMP_SLIP_NUM_TYPE.compareTo(num_type) == 0)
      {
        //ver 11.5.10.2.7 Mov Start
        //�����̃^�C�~���O�����b�N�Ƌ߂Â��邽�߈ړ�
        //slipNumVo.initQuery(Xx03ArCommonUtil.TEMP_SLIP_NUM_TYPE);
        //slipNumVo.first();
        //slipNumRow = (Xx03SlipNumbersVORowImpl)slipNumVo.getCurrentRow();
        //ver 11.5.10.2.7 Mov End
        
        if (Xx03ArCommonUtil.STR_NO.equals(headerRow.getRequestEnableFlag()))
        {
          headerRow.setRequestEnableFlag(requestEnableFlag);
        }

        // ���`�[�ԍ����쐬�̂ݕύX�Ώ�
        // ��" "�ɂď����쐬
        if (" ".compareTo(headerRow.getReceivableNum()) == 0)
        {

          //ver 11.5.10.2.7 Add Start
          slipNumVo = getXx03SlipNumbersVO1();
          slipNumVo.initQuery(Xx03ArCommonUtil.TEMP_SLIP_NUM_TYPE);
          slipNumVo.first();
          slipNumRow = (Xx03SlipNumbersVORowImpl)slipNumVo.getCurrentRow();

          try
          {
            slipNumRow.lock();
          }
          catch (OAException ex)
          {
            if (   "FND".equals(ex.getProductCode())
                && "FND_LOCK_RECORD_ERROR".equals(ex.getMessageName())
                )
            {
              throw new OAException("XX03",
                                    "APP-XX03-14163",
                                    null,
                                    OAException.ERROR,
                                    null);
            }
            else
            {
              throw OAException.wrapperException(ex);
            }
          }
          //ver 11.5.10.2.7 Add End
          
          receivableNum = new Number(slipNumRow.getSlipNumber().intValue() + 1);
          headerRow.setReceivableNum(slipNumRow.getTemporaryCode() + receivableNum.toString());
          slipNumRow.setSlipNumber(receivableNum);
        }
      }
      // �\�����̐��K�`�[�ԍ��̍̔�
      else
      {
        //ver 11.5.10.2.7 Mov Start
        ////�����̃^�C�~���O�����b�N�Ƌ߂Â��邽�߈ړ�
        //slipNumVo.initQuery(Xx03ArCommonUtil.NON_TEMP_SLIP_NUM_TYPE);
        //slipNumVo.first();
        //slipNumRow = (Xx03SlipNumbersVORowImpl)slipNumVo.getCurrentRow();
        //ver 11.5.10.2.7 Mov End
        
        if (Xx03ArCommonUtil.STR_NO.equals(headerRow.getRequestEnableFlag()))
        {
          headerRow.setRequestEnableFlag(requestEnableFlag);
        }

        //ver 11.5.10.2.7 Add Start
        slipNumVo = getXx03SlipNumbersVO1();
        // ���ԍ��̐ړ�����VO����擾����
        slipNumVo.initQuery(Xx03ArCommonUtil.TEMP_SLIP_NUM_TYPE);
        slipNumVo.first();
        slipNumRow = (Xx03SlipNumbersVORowImpl)slipNumVo.getCurrentRow();
        String tempCode = slipNumRow.getTemporaryCode();
        //ver 11.5.10.2.7 Mov End

        // ���`�[�ԍ������쐬�̂ݕύX�Ώ�
        if (((headerRow.getReceivableNum().length() > 3) &&
        //Ver11.5.10.2.6C Change Start
        //���ԍ��̐ړ�����VO����擾�����l�ɕύX
        //  (headerRow.getReceivableNum().substring(0,3).compareTo(Xx03ArCommonUtil.TEMP_CODE) == 0))
          (headerRow.getReceivableNum().substring(0,3).compareTo(tempCode) == 0))
        //Ver11.5.10.2.6C Change End
          || (" ".compareTo(headerRow.getReceivableNum()) == 0))
        {

          //ver 11.5.10.2.7 Add Start
          slipNumVo.initQuery(Xx03ArCommonUtil.NON_TEMP_SLIP_NUM_TYPE);
          slipNumVo.first();
          slipNumRow = (Xx03SlipNumbersVORowImpl)slipNumVo.getCurrentRow();

          try
          {
            slipNumRow.lock();
          }
          catch (OAException ex)
          {
            if (   "FND".equals(ex.getProductCode())
                && "FND_LOCK_RECORD_ERROR".equals(ex.getMessageName())
                )
            {
              throw new OAException("XX03",
                                    "APP-XX03-14163",
                                    null,
                                    OAException.ERROR,
                                    null);
            }
            else
            {
              throw OAException.wrapperException(ex);
            }
          }
          //ver 11.5.10.2.7 Add End

          receivableNum = new Number(slipNumRow.getSlipNumber().intValue() + 1);
          headerRow.setReceivableNum(receivableNum.toString());
          slipNumRow.setSlipNumber(receivableNum);
        }
      }

      // �I������
      endProcedure(getClass().getName(), methodName);
    }
    finally
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();
      }
    }
  } // publishNum()

  /**
   * �x���\����擾
   * @param �Ȃ�
   * @return �Ȃ�
   */
  public void getDueDate()
  {
    // ����������
    String methodName = "getDueDate";
    startProcedure(getClass().getName(), methodName);

    // �r���[�E�I�u�W�F�N�g�̎擾
    int fetchedHeaderRowCount;
    RowSetIterator selectHeaderIter = null;
    OAViewObject headerVo = getXx03ReceivableSlipsVO1();

    try
    {
      Xx03ReceivableSlipsVORowImpl headerRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedHeaderRowCount = headerVo.getFetchedRowCount();
      fetchedHeaderRowCount = headerVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectHeaderIter = headerVo.createRowSetIterator("selectHeaderIter");

      if (fetchedHeaderRowCount > 0)
      {
        selectHeaderIter.setRangeStart(0);
        selectHeaderIter.setRangeSize(fetchedHeaderRowCount);

        headerRow = (Xx03ReceivableSlipsVORowImpl)selectHeaderIter.first();
      } // fetchedHeaderRocCount
      else
      {
        // �G���[�E���b�Z�[�W
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);
      } // fetchedHeaderRowCount
      // �x�������̎Z�o
      if ((headerRow.getTermsId() != null) && (headerRow.getInvoiceDate() != null))
      {
        Date dueDate = calcDueDate(headerRow.getTermsId(), headerRow.getInvoiceDate());
        headerRow.setPaymentScheduledDate(dueDate);
      }

      // �I������
      endProcedure(getClass().getName(), methodName);
    }
    finally
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();
      }
    }
  } // getDueDate()

  /**
   * �`�[�̕ۑ�
   * @param �Ȃ�
   * @return �Ȃ�
   */
  public void save()
  {
    // ����������
    String methodName = "save";
    startProcedure(getClass().getName(), methodName);

    // �ꌩ�ڋq�t���O��'Y'�ȊO�̎��͈ꌩ�ڋq���J�����̓��e���N���A
    // �r���[�E�I�u�W�F�N�g�̎擾
    int fetchedHeaderRowCount;
    RowSetIterator selectHeaderIter = null;
    OAViewObject headerVo = getXx03ReceivableSlipsVO1();

    try
    {
      Xx03ReceivableSlipsVORowImpl headerRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedHeaderRowCount = headerVo.getFetchedRowCount();
      fetchedHeaderRowCount = headerVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectHeaderIter = headerVo.createRowSetIterator("selectHeaderIter");

      if (fetchedHeaderRowCount > 0)
      {
        selectHeaderIter.setRangeStart(0);
        selectHeaderIter.setRangeSize(fetchedHeaderRowCount);

        headerRow = (Xx03ReceivableSlipsVORowImpl)selectHeaderIter.first();
      } // fetchedHeaderRocCount
      else
      {
        // �G���[�E���b�Z�[�W
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);
      } // fetchedHeaderRowCount
    
      // �ꌩ�ڋq�t���O�`�F�b�N
      String firstCustomerFlag = headerRow.getFirstCustomerFlag();
      if ((firstCustomerFlag == null) || (!firstCustomerFlag.equals(Xx03ArCommonUtil.STR_YES))){
        // �ꌩ�ڋq�敪'Y'�ȊO�̏ꍇ�A�ꌩ�ڋq���N���A
        headerRow.setOnetimeCustomerName(null);
        headerRow.setOnetimeCustomerKanaName(null);
        headerRow.setOnetimeCustomerAddress1(null);
        headerRow.setOnetimeCustomerAddress2(null);
        headerRow.setOnetimeCustomerAddress3(null);
      }

      try
      {
        // COMMIT
        getTransaction().commit();
      }
      catch(OAException ex)
      {
        throw OAException.wrapperException(ex);
      }

      // �I������
      endProcedure(getClass().getName(), methodName);
    }
    finally
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();
      }
    }
  } // save()

  /**
   * ���ׂ̃R�s�[
   * @param �Ȃ�
   * @return �Ȃ�
   */
  public void copyLine()
  {
    // ����������
    String methodName = "copyLine";
    startProcedure(getClass().getName(), methodName);
    
    RowSetIterator selectIter = null;

    //Ver11.5.10.2.6B Add Start
    RowSetIterator selectIter2 = null;
    int addRowFlag = 0;
    int addRowIdx  = 0;
    //Ver11.5.10.2.6B Add End

    int fetchedRowCount;
    int rowCount;
    int nocheck = 0;

    //Ver11.5.10.1.6M Add Start
    removeEmptyRows();
    //Ver11.5.10.1.6M Add End

    try
    {
      // �r���[�E�I�u�W�F�N�g�̎擾
      OAViewObject lineVo = getXx03ReceivableSlipsLineVO1();

      if (lineVo == null)
      {
        // �G���[�E���b�Z�[�W
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsLineVO1")};
        throw new OAException("XX03", "APP-XX03-13035", tokens);
      }
    
      Xx03ReceivableSlipsLineVORowImpl lineRow = null;
      Row newLineRow = null; 

      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedRowCount = lineVo.getFetchedRowCount();
      fetchedRowCount = lineVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End

      selectIter = lineVo.createRowSetIterator("selectIter");
      //Ver11.5.10.2.6B Add Start
      selectIter2 = lineVo.createRowSetIterator("selectIter2");
      //Ver11.5.10.2.6B Add End

      if (fetchedRowCount > 0)
      {
// ver1.2 Add Start �R�s�[������GL�����ɕύX
        Vector deleteLineIdx = new Vector();
// ver1.2 Add End
        
        selectIter.setRangeStart(0);
        selectIter.setRangeSize(fetchedRowCount);

// ver1.2 Change Start �R�s�[������GL�����ɕύX
//        for (int i=fetchedRowCount-1; i>=0; i--)
        for (int i=0; i<fetchedRowCount; i++)
// ver1.2 Change End
        {
          lineRow = (Xx03ReceivableSlipsLineVORowImpl)selectIter.getRowAtRangeIndex(i);

// ver1.2 Delete Start �R�s�[������GL�����ɕύX
//          // �}���ʒu
//          // �����̉��ɃR�s�[����
//          lineVo.setCurrentRowAtRangeIndex(i);
//          lineVo.next();
// ver1.2 Delete End

          if (lineRow != null)
          {
            Number receivableLineId = lineRow.getReceivableLineId();
            Number receivableId = lineRow.getReceivableId();
            String selectSwitcher = lineRow.getSelectSwitcher();

            //Ver11.5.10.2.3C Add Start
            lineRow.setSelectSwitcher(null);
            //Ver11.5.10.2.3C Add End

            // �����l���ύX���Ă��Ȃ��ꍇ(�󔒍s�j
            if (!lineRow.isInput())
            {
// ver1.2 Change Start �R�s�[������GL�����ɕύX
//              lineRow.remove();
              deleteLineIdx.add(new Integer(i));
// ver1.2 Change End
              nocheck++;
            }
            // �����l���ύX���Ă���ꍇ
            else
            {
              if ((selectSwitcher == null) || (receivableId == null))
              {
                nocheck++;
              }
              else if ((Xx03ArCommonUtil.STR_YES.compareTo(selectSwitcher)) == 0)
              {
                //Ver11.5.10.2.6B Chg Start
                //lineVo.last();
                //lineVo.next();
                selectIter2.last();
                selectIter2.next();
                //Ver11.5.10.2.6B Chg End

                //Ver11.5.10.1.6M Change Start
                try
                {
                  //Ver11.5.10.2.6B Chg Start
                  //newLineRow = lineVo.createAndInitRow(lineRow);
                  //newLineRow.setAttribute("LineNumber", new Number(fetchedRowCount+i+1));
                  //lineVo.insertRow(newLineRow);
                  newLineRow = selectIter2.createAndInitRow(lineRow);
                  newLineRow.setAttribute("LineNumber", new Number(fetchedRowCount+i+1));
                  selectIter2.insertRow(newLineRow);
                  
                  if (addRowFlag == 0)
                  {
                    lineVo.last();
                    addRowIdx  = lineVo.getCurrentRowIndex();
                    addRowFlag = 1;
                  }
                  //Ver11.5.10.2.6B Chg End
                }
                catch(Exception e) 
                {
                  newLineRow.remove();
                  throw OAException.wrapperException(e);
                }
                //Ver11.5.10.1.6M Change End
              }
              else
              {
                nocheck++;
              }
            }
          } // lineRow != null
        } // for loop

        if (fetchedRowCount == nocheck)
        {
          throw new OAException("XX03",
                                "APP-XX03-13050",
                                null,
                                OAException.ERROR,
                                null);
        }

// ver1.2 Add Start �R�s�[������GL�����ɕύX
        // ��s���폜
        for (int i=deleteLineIdx.size()-1; i>=0; i--)
        {
          int deleteIdx = Integer.parseInt(deleteLineIdx.elementAt(i).toString());
          lineRow = (Xx03ReceivableSlipsLineVORowImpl)selectIter.getRowAtRangeIndex(deleteIdx);
          lineRow.remove();
        } // for loop
// ver1.2 Add End

        //Ver11.5.10.2.6B Add Start
        lineVo.setRangeSize(5);
        addRowIdx = addRowIdx - addRowIdx % 5;
        lineVo.setRangeStart(addRowIdx);
        //Ver11.5.10.2.6B Add End

      } // fetchedRowCount > 0

      // �I������
      endProcedure(getClass().getName(), methodName);
    }
    finally
    {
      if(selectIter != null)
      {
        selectIter.closeRowSetIterator();
      }
      //Ver11.5.10.2.6B Add Start
      if(selectIter2 != null)
      {
        selectIter2.closeRowSetIterator();
      }
      //Ver11.5.10.2.6B Add End
    }
  } // copyLine()

  /**
   * ���ׂ̍폜
   * @param �Ȃ�
   * @return �Ȃ�
   */
  public void deleteLine()
  {
    // ����������
    String methodName = "deleteLine";
    startProcedure(getClass().getName(), methodName);  

    RowSetIterator selectIter = null;
    int fetchedRowCount;
    int nocheck = 0;

    try
    {
      // �r���[�E�I�u�W�F�N�g�̎擾
      OAViewObject lineVo = getXx03ReceivableSlipsLineVO1();
    
      Xx03ReceivableSlipsLineVORowImpl lineRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedRowCount = lineVo.getFetchedRowCount();
      fetchedRowCount = lineVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectIter = lineVo.createRowSetIterator("selectIter");
    
      if (fetchedRowCount > 0)
      {
        Vector deleteLineIdx = new Vector();
        
        selectIter.setRangeStart(0);
        selectIter.setRangeSize(fetchedRowCount);

        for (int i=fetchedRowCount-1; i>=0; i--)
        {
          lineRow = (Xx03ReceivableSlipsLineVORowImpl)selectIter.getRowAtRangeIndex(i);

          if (lineRow != null)
          {
            Number cachedReceivableLineId = lineRow.getReceivableLineId();
            Number cachedReceivableId = lineRow.getReceivableId();
            String cachedSelectSwitcher = lineRow.getSelectSwitcher();
            
            // �����l���ύX���Ă��Ȃ��ꍇ(�󔒍s�j
            if (!lineRow.isInput())
            {
              lineRow.remove();
              nocheck++;
            }
            // �����l���ύX���Ă���ꍇ
            else
            {
              if ((cachedSelectSwitcher == null) || (cachedReceivableId == null))
              {     
                nocheck++;
              }
              else if ((Xx03ArCommonUtil.STR_YES.compareTo(cachedSelectSwitcher)) == 0)  
              {
                lineRow.remove();
              }
              else
              {
                nocheck++;
              }
            }
          } // lineRow != null
        } // for loop

        if (fetchedRowCount == nocheck)
        {
          throw new OAException("XX03",
                                "APP-XX03-13050",
                                null,
                                OAException.ERROR,
                                null);
        }
      } // fetchedRowCount > 0

      // �I������
      endProcedure(getClass().getName(), methodName);
    }
    finally
    {
      if(selectIter != null)
      {
        selectIter.closeRowSetIterator();
      }
    }
  } // deleteLine()

  /**
   * �U�֓`�[���ׂ̒ǉ�
   * @param slipType �`�[���
   * @return �Ȃ�
   */
  public void addReceivableSlipLines()
  {
    // ����������
    String methodName = "addReceivableSlipLines";
    startProcedure(getClass().getName(), methodName);

    // ���׍s�쐬
    createReceivableDetailLines(5, true);

    // �I������
    endProcedure(getClass().getName(), methodName);    
  } // addReceivableSlipLines()

  /**
   * ���הԍ��̍̔�
   * @param �Ȃ�
   * @return �Ȃ�
   */
  public void resetLineNumber()
  {
    // ����������
    String methodName = "resetLineNumber";
    startProcedure(getClass().getName(), methodName);

    Number newLineNumber = new Number(1);
    RowSetIterator selectIter = null;
    int fetchedRowCount;

    try
    {
      // �r���[�E�I�u�W�F�N�g�̎擾
      OAViewObject lineVo = getXx03ReceivableSlipsLineVO1();

      if (lineVo == null)
      {
        // �G���[�E���b�Z�[�W
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsLineVO1")};
        throw new OAException("XX03", "APP-XX03-13035", tokens);
      }

      Xx03ReceivableSlipsLineVORowImpl lineRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedRowCount = lineVo.getFetchedRowCount();
      fetchedRowCount = lineVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectIter = lineVo.createRowSetIterator("selectIter");

      if (fetchedRowCount > 0)
      {
        selectIter.setRangeStart(0);
        selectIter.setRangeSize(fetchedRowCount);

        for (int i=0; i<fetchedRowCount; i++)
        {
          lineRow = (Xx03ReceivableSlipsLineVORowImpl)selectIter.getRowAtRangeIndex(i);

          if (lineRow != null)
          {
            Number cachedReceivableLineId = lineRow.getReceivableLineId();
            Number cachedLineNumber = lineRow.getLineNumber();
            String cachedSegment1 = lineRow.getSegment1();
            newLineNumber = new Number(i+1);
          
            if (cachedLineNumber.compareTo(newLineNumber) != 0)
            {
              ((Xx03ReceivableSlipsLineVORowImpl)lineRow).setLineNumber(new Number(i+1));          

              // �v�C��
              // �C�������ۂ��𔻒f������@
              // ���f�p�̃J�����̒ǉ��H
              if (cachedSegment1 == null)
              {
                lineRow.setNewRowState(Row.STATUS_INITIALIZED);
              }
            }
          } // lineRow != null
        } // for loop
      } // fetchedRowCount > 0

      // �I������
      endProcedure(getClass().getName(), methodName);
    }
    finally
    {
      if(selectIter != null)
      {
        selectIter.closeRowSetIterator();
      }
    }
  } // resetLineNumber()

  /**
   * ������v�擾
   * @param �Ȃ�
   * @return �Ȃ�
   */
  public void getAutoAccounting()
  {
    // ����������
    String methodName = "getAutoAccounting";
    startProcedure(getClass().getName(), methodName);
    
    RowSetIterator selectHeaderIter = null;
    RowSetIterator selectIter = null;
    int fetchedHeaderRowCount;
    int fetchedRowCount;
    int rowCount;

    try
    {
      // �r���[�E�I�u�W�F�N�g�̎擾
      OAViewObject headerVo = getXx03ReceivableSlipsVO1();
      OAViewObject lineVo = getXx03ReceivableSlipsLineVO1();

      if (headerVo ==null || lineVo == null)
      {
        // �G���[�E���b�Z�[�W
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsLineVO1")};
        throw new OAException("XX03", "APP-XX03-13035", tokens);
      }
    
      Xx03ReceivableSlipsVORowImpl headerRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedHeaderRowCount = headerVo.getFetchedRowCount();
      fetchedHeaderRowCount = headerVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectHeaderIter = headerVo.createRowSetIterator("selectHeaderIter");

      String entryDepartment = null;
      Number customerId = null;
      Number customerOfficeId = null;
      if (fetchedHeaderRowCount > 0)
      {
        selectHeaderIter.setRangeStart(0);
        selectHeaderIter.setRangeSize(fetchedHeaderRowCount);

        headerRow = (Xx03ReceivableSlipsVORowImpl)selectHeaderIter.first();

        if (headerRow != null){
          entryDepartment = headerRow.getEntryDepartment();
          customerId = headerRow.getCustomerId();
          customerOfficeId = headerRow.getCustomerOfficeId();
        } // headerRow
      } // fetchedHeaderRocCount
      else
      {
        // �G���[�E���b�Z�[�W
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);
      } // fetchedHeaderRowCount
    
      Xx03ReceivableSlipsLineVORowImpl lineRow = null;
      Row newLineRow = null; 

      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedRowCount = lineVo.getFetchedRowCount();
      fetchedRowCount = lineVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectIter = lineVo.createRowSetIterator("selectIter");

      if (fetchedRowCount > 0)
      {
        selectIter.setRangeStart(0);
        selectIter.setRangeSize(fetchedRowCount);

        for (int i=0; i<fetchedRowCount; i++)
        {
          lineRow = (Xx03ReceivableSlipsLineVORowImpl)selectIter.getRowAtRangeIndex(i);

          if (lineRow != null)
          {
            Number cachedReceivableLineId = lineRow.getReceivableLineId();
            Number cachedReceivableId = lineRow.getReceivableId();
            String cachedSelectSwitcher = lineRow.getSelectSwitcher();
 
            if ((cachedSelectSwitcher == null) || (cachedReceivableId == null))
            {     
            }
            else if ((Xx03ArCommonUtil.STR_YES.compareTo(cachedSelectSwitcher)) == 0)
            {
              getAutoAccountingData(entryDepartment, customerId, customerOfficeId, lineRow);
            }
          } // lineRow != null
        } // for loop
      } // fetchedRowCount > 0

      // �I������
      endProcedure(getClass().getName(), methodName);
    }
    finally
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();
      }
      if(selectIter != null)
      {
        selectIter.closeRowSetIterator();
      }
    }
  } // getAutoAccounting()

  /**
   * ������v�擾(�^�u������)
   * @param �Ȃ�
   * @return �Ȃ�
   */
  public void getAutoAccountingTab()
  {
    // ����������
    String methodName = "getAutoAccountingTab";
    startProcedure(getClass().getName(), methodName);
    
    RowSetIterator selectHeaderIter = null;
    RowSetIterator selectIter = null;
    int fetchedHeaderRowCount;
    int fetchedRowCount;
    int rowCount;

    try
    {
      // �r���[�E�I�u�W�F�N�g�̎擾
      OAViewObject headerVo = getXx03ReceivableSlipsVO1();
      OAViewObject lineVo = getXx03ReceivableSlipsLineVO1();

      if (headerVo ==null || lineVo == null)
      {
        // �G���[�E���b�Z�[�W
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsLineVO1")};
        throw new OAException("XX03", "APP-XX03-13035", tokens);
      }
    
      Xx03ReceivableSlipsVORowImpl headerRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedHeaderRowCount = headerVo.getFetchedRowCount();
      fetchedHeaderRowCount = headerVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectHeaderIter = headerVo.createRowSetIterator("selectHeaderIter");

      String entryDepartment = null;
      Number customerId = null;
      Number customerOfficeId = null;
      if (fetchedHeaderRowCount > 0)
      {
        selectHeaderIter.setRangeStart(0);
        selectHeaderIter.setRangeSize(fetchedHeaderRowCount);

        headerRow = (Xx03ReceivableSlipsVORowImpl)selectHeaderIter.first();

        if (headerRow != null){
          entryDepartment = headerRow.getEntryDepartment();
          customerId = headerRow.getCustomerId();
          customerOfficeId = headerRow.getCustomerOfficeId();
        } // headerRow
      } // fetchedHeaderRocCount
      else
      {
        // �G���[�E���b�Z�[�W
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);
      } // fetchedHeaderRowCount
    
      Xx03ReceivableSlipsLineVORowImpl lineRow = null;
      Row newLineRow = null; 

      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedRowCount = lineVo.getFetchedRowCount();
      fetchedRowCount = lineVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End

      selectIter = lineVo.createRowSetIterator("selectIter");

      if (fetchedRowCount > 0)
      {
        selectIter.setRangeStart(0);
        selectIter.setRangeSize(fetchedRowCount);

        for (int i=0; i<fetchedRowCount; i++)
        {
          lineRow = (Xx03ReceivableSlipsLineVORowImpl)selectIter.getRowAtRangeIndex(i);

          if ((lineRow != null) &&
              ((lineRow.getSlipLineType() != null) && (!"".equals(lineRow.getSlipLineType().toString()))) &&
              ((lineRow.getSegment1() == null) || ("".equals(lineRow.getSegment1()))) &&
              ((lineRow.getSegment2() == null) || ("".equals(lineRow.getSegment2()))) &&
              ((lineRow.getSegment3() == null) || ("".equals(lineRow.getSegment3()))) &&
              ((lineRow.getSegment4() == null) || ("".equals(lineRow.getSegment4()))) &&
              ((lineRow.getSegment5() == null) || ("".equals(lineRow.getSegment5()))) &&
              ((lineRow.getSegment6() == null) || ("".equals(lineRow.getSegment6()))) &&
              ((lineRow.getSegment7() == null) || ("".equals(lineRow.getSegment7()))) &&
              ((lineRow.getSegment8() == null) || ("".equals(lineRow.getSegment8())))
             )
          {
            Number cachedReceivableLineId = lineRow.getReceivableLineId();
            Number cachedReceivableId = lineRow.getReceivableId();
            String autoTaxExec = lineRow.getAutoTaxExec();    // ������v���s�σt���O
 
            if ((cachedReceivableId == null))
            {     
            }
            else if ((autoTaxExec != null) && (!autoTaxExec.equals("Y")))
            {
              // ������v�����s
              getAutoAccountingData(entryDepartment, customerId, customerOfficeId, lineRow);
            }
          } // lineRow != null
        } // for loop
      } // fetchedRowCount > 0

      // �I������
      endProcedure(getClass().getName(), methodName);
    }
    finally
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();
      }
      if(selectIter != null)
      {
        selectIter.closeRowSetIterator();
      }
    }
  } // getAutoAccountingTab()

  /**
   * ������v���擾
   * @param entryDepartment ��������R�[�h
   * @param customerId �ڋqID
   * @param customerOfficeId �ڋq���Ə�ID
   * @param lineRow ���׍s
   * @return �Ȃ�
   */
  public void getAutoAccountingData(String entryDepartment, Number customerId, 
     Number customerOfficeId, Xx03ReceivableSlipsLineVORowImpl lineRow)
  {
    // ����������
    String methodName = "getAutoAccountingData";
    startProcedure(getClass().getName(), methodName);

/*
    // ���
    lineRow.setSegment1("100");
*/

    // ����
    if (entryDepartment != null)
    {
      lineRow.setSegment2(entryDepartment); 
    }

    // ����ȖځA�⏕�Ȗ�
    Number memoLineId = lineRow.getSlipLineType();  // ��������ID
    if (memoLineId != null)
    {
      Xx03GetAutoAccountInfoMemoVOImpl vo = getXx03GetAutoAccountInfoMemoVO1();
      Xx03GetAutoAccountInfoMemoVORowImpl row = null;
      vo.initQuery(memoLineId);
      row = (Xx03GetAutoAccountInfoMemoVORowImpl)vo.first();
      if (row != null)
      {
        lineRow.setSegment1(row.getSegment1());
//        lineRow.setSegment2(row.getSegment2());
        lineRow.setSegment3(row.getSegment3());
        lineRow.setSegment4(row.getSegment4());
        lineRow.setSegment6(row.getSegment6());
        lineRow.setSegment7(row.getSegment7());
        lineRow.setSegment8(row.getSegment8()); 
      }
    }

    // �����
    if ((customerId != null) && (customerOfficeId != null))
    {
      Xx03GetAutoAccountInfoCustomerVOImpl vo = getXx03GetAutoAccountInfoCustomerVO1();
      Xx03GetAutoAccountInfoCustomerVORowImpl row = null;
      vo.initQuery(customerId, customerOfficeId);
      row = (Xx03GetAutoAccountInfoCustomerVORowImpl)vo.first();
      if (row != null)
      {
        lineRow.setSegment5(row.getSegment5());
      }
    }

/*
    // ���Ƌ敪
    lineRow.setSegment6("090");

    // �v���W�F�N�g
    lineRow.setSegment7("0");

    // �\��
    lineRow.setSegment8("0");
*/

    // ������v���s�σt���O
    lineRow.setAutoTaxExec(Xx03ArCommonUtil.STR_YES);
    
    // �I������
    endProcedure(getClass().getName(), methodName);
  } // getAutoAccounting()

  /**
   * �O����{�^���\���敪�擾
   * @param �Ȃ�
   * @return �O����\���敪
   */
  public String getPrePayButton()
  {
    // ����������
    String methodName = "getPrePayButton";
    startProcedure(getClass().getName(), methodName);
    
    RowSetIterator selectHeaderIter = null;     
    int fetchedHeaderRowCount;
    String retStr = "N";  // �O����\���敪

    try
    {
      OAViewObject headerVo = getXx03ReceivableSlipsVO1();
      Xx03PrePayButtonVOImpl prepayVo = getXx03PrePayButtonVO1();
      Xx03ReceivableSlipsVORowImpl headerRow = null;
      Xx03PrePayButtonVORowImpl prepayRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedHeaderRowCount = headerVo.getFetchedRowCount();
      fetchedHeaderRowCount = headerVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectHeaderIter = headerVo.createRowSetIterator("selectHeaderIter");

      if (fetchedHeaderRowCount > 0)
      {
        selectHeaderIter.setRangeStart(0);
        selectHeaderIter.setRangeSize(fetchedHeaderRowCount);

        headerRow = (Xx03ReceivableSlipsVORowImpl)selectHeaderIter.first();

        if (headerRow != null){
          // �`�[��ʎ擾
          String slipType = headerRow.getSlipType();
      
          // �O����\���敪�擾
          prepayVo.initQuery(slipType);
          prepayRow = (Xx03PrePayButtonVORowImpl)prepayVo.first();
          retStr = prepayRow.getAttribute12();
        } // headerRow
      } // fetchedHeaderRocCount
      else
      {
        // �G���[�E���b�Z�[�W
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);        
      } // fetchedHeaderRowCount 
    
      // �I������
      endProcedure(getClass().getName(), methodName);
    }
    finally
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();
      }
    }
    return retStr;
  } // getPrePayButton() 

  /**
   * �㏑�̋��V�X�e���I�v�V�����擾
   * @param �Ȃ�
   * @return �㏑�̋��V�X�e���I�v�V�����l
   */
  public String getTaxOverride()
  {
    // ��������
    String methodName = "getTaxOverride";
    startProcedure(getClass().getName(), methodName);
    
    String retValue = null;
    
    // �㏑�̋��V�X�e���I�v�V�������擾����
    Xx03GetTaxOverrideVOImpl vo = getXx03GetTaxOverrideVO1();
    vo.executeQuery();
    vo.first();
    Xx03GetTaxOverrideVORowImpl row =
      (Xx03GetTaxOverrideVORowImpl)vo.getCurrentRow();
    retValue = row.getTaxRoundingAllowOverride();
    if(retValue == null)
    {
      retValue = "";
    }

    // �I������
    endProcedure(getClass().getName(), methodName);  
    return retValue;
  } // getTaxOverride()

  /**
   *
   * �@�\�ʉ݂̎擾
   *
   * @return  �@�\�ʉ�
   */
  private String getCurrencyCode()
  {
    // ����������
    String methodName = "getCurrencyCode";
    startProcedure(getClass().getName(), methodName);

    Xx03PrecisionVORowImpl row = null;

    try
    {
      // �r���[�E�I�u�W�F�N�g�̎擾
      Xx03PrecisionVOImpl vo = getXx03PrecisionVO1();
      vo.executeQuery();
      vo.first();

      row = (Xx03PrecisionVORowImpl)vo.getCurrentRow();
    }
    catch(OAException ex)
    {
      throw OAException.wrapperException(ex);
    }

    // �I������
    endProcedure(getClass().getName(), methodName);
    return row.getCurrencyCode();
  } // getCurrencyCode

  /**
   * �ڋq�A�ڋq���Ə��̏���Ōv�Z���x���A����Œ[���������擾����
   * @param customerId �ڋqID
   * @param customerOfficeId �ڋq���Ə�ID
   */
  private Hashtable getCustomerTaxOption(Number customerId, Number customerOfficeId)
  {
    // ����������
    String methodName = "getCustomerTaxOption";
    startProcedure(getClass().getName(), methodName);

    Hashtable returnHashTable = new Hashtable();
    String taxCalcFlag = "";
    String taxRoundingRule = "";

    // �ڋq�A�ڋq���Ə��̏���Ōv�Z���x���A����Œ[�������擾
    // �r���[�E�I�u�W�F�N�g�̎擾
    Xx03CustTaxOptionVOImpl vo = getXx03CustTaxOptionVO1();
    vo.initQuery(customerId, customerOfficeId);

    if (vo != null)
    {
      // VO not null
      Xx03CustTaxOptionVORowImpl row = (Xx03CustTaxOptionVORowImpl)vo.first();
      if (row != null)
      {
        // ROW not null
        //Ver11.5.10.1.5B 2005/09/27 Change Start
        // ����Ōv�Z���x���擾
        if ((row.getTaxHeaderLevelFlag() != null) 
          && (!row.getTaxHeaderLevelFlag().equals("")))
        {
          // �ڋq���Ə��̏���Ōv�Z���x���l����
          taxCalcFlag = row.getTaxHeaderLevelFlag();
        }
        else
        {
          // �ڋq���Ə��̏���Ōv�Z���x���l�Ȃ� �� �ڋq�̏���Ōv�Z���x���l�擾
          if ((row.getTaxHeaderLevelFlagC() != null) 
            && (!row.getTaxHeaderLevelFlagC().equals("")))
          {
            // �ڋq�̏���Ōv�Z���x���l����
            taxCalcFlag = row.getTaxHeaderLevelFlagC();
          }
        }

        // ����Œ[�������擾
        if ((row.getTaxRoundingRule() != null) 
            && (!row.getTaxRoundingRule().equals("")))
        {
          // �ڋq���Ə��̏���Œ[�������l����
          taxRoundingRule = row.getTaxRoundingRule();
        }
        else
        {
          // �ڋq���Ə��̏���Œ[�������l�Ȃ� �� �ڋq�̏���Œ[�������l�擾
          if ((row.getTaxRoundingRuleC() != null) 
            && (!row.getTaxRoundingRuleC().equals("")))
          {
            // �ڋq�̏���Œ[�������l����
            taxRoundingRule = row.getTaxRoundingRuleC();
          }
        }
        // // �ڋq���Ə��̒l�擾
        //if ((row.getTaxHeaderLevelFlag() != null) 
        //    && (!row.getTaxHeaderLevelFlag().equals(""))
        //    && (row.getTaxRoundingRule() != null)
        //    && (!row.getTaxRoundingRule().equals("")))
        //{
        //  // �ڋq���Ə��̏���ŃI�v�V�����l����
        //  taxCalcFlag = row.getTaxHeaderLevelFlag();
        //  taxRoundingRule = row.getTaxRoundingRule();
        //}
        //else
        //{
        //  // �ڋq���Ə��̏���ŃI�v�V�����l�Ȃ� �� �ڋq�̏���ŃI�v�V�����l�擾
        //  if ((row.getTaxHeaderLevelFlagC() != null) 
        //      && (!row.getTaxHeaderLevelFlagC().equals(""))
        //      && (row.getTaxRoundingRuleC() != null)
        //      && (!row.getTaxRoundingRuleC().equals("")))
        //  {
        //    // �ڋq�̏���ŃI�v�V�����l����
        //    taxCalcFlag = row.getTaxHeaderLevelFlagC();
        //    taxRoundingRule = row.getTaxRoundingRuleC();
        //  }
        //}
        //Ver11.5.10.1.5B 2005/09/27 Change End
      }
    }

    // �߂�l�Z�b�g
    returnHashTable.put("taxCalcFlag", taxCalcFlag);
    returnHashTable.put("taxRoundingRule", taxRoundingRule);
    
    // �I������
    endProcedure(getClass().getName(), methodName);
    return returnHashTable;
  } // getCustomerTaxOption

  /**
   * �V�X�e���I�v�V�����̏���Ōv�Z���x���A����Œ[���������擾����
   */
  private Hashtable getSystemTaxOption()
  {
    // 2006/01/23 Ver11.5.10.1.6L Add Start
    OADBTransaction txn = getOADBTransaction();
    // 2006/01/23 Ver11.5.10.1.6L Add End
    // ����������
    String methodName = "getSystemTaxOption";
    startProcedure(getClass().getName(), methodName);

    Hashtable returnHashTable = new Hashtable();
    String taxCalcFlag = "";
    String taxRoundingRule = "";

    // �ڋq�A�ڋq���Ə��̏���Ōv�Z���x���A����Œ[�������擾
    // �r���[�E�I�u�W�F�N�g�̎擾
    Xx03SystemTaxOptionVOImpl vo = getXx03SystemTaxOptionVO1();
    vo.executeQuery();
    Xx03SystemTaxOptionVORowImpl row = (Xx03SystemTaxOptionVORowImpl)vo.first();
    if (row != null)
    {
      // ROW not null
      if ((row.getTaxHeaderLevelFlag() != null) 
          && (!row.getTaxHeaderLevelFlag().equals(""))
          && (row.getTaxRoundingRule() != null)
          && (!row.getTaxRoundingRule().equals("")))
      {
        // �V�X�e���I�v�V�����l����
        taxCalcFlag = row.getTaxHeaderLevelFlag();
        taxRoundingRule = row.getTaxRoundingRule();
      }
      else
      {
        // �V�X�e���I�v�V�����l�Ȃ�
        // 2006/01/23 Ver11.5.10.1.6L Change Start
        //MessageToken[] tokens = {new MessageToken("OBJECT_NAME", Xx03ArCommonUtil.MESSAGE_STR_GL_TAX_INFO)};
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", txn.getMessage("XX03","APP-XX03-34062",null))};
        // 2006/01/23 Ver11.5.10.1.6L Change End
        throw new OAException("XX03","APP-XX03-13036", tokens);
      }
    }
    else
    {
      // �V�X�e���I�v�V�����l�Ȃ�
      // 2006/01/23 Ver11.5.10.1.6L Change Start
      //MessageToken[] tokens = {new MessageToken("OBJECT_NAME", Xx03ArCommonUtil.MESSAGE_STR_GL_TAX_INFO)};
      MessageToken[] tokens = {new MessageToken("OBJECT_NAME", txn.getMessage("XX03","APP-XX03-34062",null))};
      // 2006/01/23 Ver11.5.10.1.6L Change End
      throw new OAException("XX03","APP-XX03-13036", tokens);
    }

    // �߂�l�Z�b�g
    returnHashTable.put("taxCalcFlag", taxCalcFlag);
    returnHashTable.put("taxRoundingRule", taxRoundingRule);
    
    // �I������
    endProcedure(getClass().getName(), methodName);
    return returnHashTable;
  } // getSystemTaxOption

  /**
   *
   * �`�[��ʂ̎擾
   *
   * @param   slipTypeCode  �`�[��ʃR�[�h
   * @return  ���x
   */
  public Serializable getSlipTypeName(String slipTypeCode)
  {
    // ����������
    String methodName = "getSlipTypeName";
    startProcedure(getClass().getName(), methodName);

    Xx03SlipTypesLovVORowImpl row = null;

    try
    {
      // �r���[�E�I�u�W�F�N�g�̎擾
      Xx03SlipTypesLovVOImpl vo = getXx03SlipTypesLovVO1();
      vo.initQuery(slipTypeCode);
      vo.first();

      row = (Xx03SlipTypesLovVORowImpl)vo.getCurrentRow();
    }
    catch(OAException ex)
    {
      throw OAException.wrapperException(ex);
    }

    // �I������
    endProcedure(getClass().getName(), methodName);
    return row.getDescription();
  } // getSlipTypeName

  /**
   *
   * �`�[�̕ύX���
   */
  public void rollback()
  {
    // ����������
    String methodName = "rollback";
    startProcedure(getClass().getName(), methodName);

    try
    {
      Transaction txn = getTransaction();

      if (txn.isDirty())
      {
        txn.rollback();
      }
    }
    catch(OAException ex)
    {
      throw OAException.wrapperException(ex);
    }

    // �I������
    endProcedure(getClass().getName(), methodName);
  } // rollback()

  /**
   * �O��[���`�[�g�p�`�F�b�N
   * @param commitmentNumber �`�F�b�N�ΏۑO��[���`�[�ԍ�
   * @param receivableNum �`�F�b�N�Ώۓ`�[�ԍ�
   * @return  �Y���O��[���`�[���g�p���̓`�[�ԍ�
   */
  public String checkCommitmentNumber(String commitmentNumber, String receivableNum)
  {
    // ����������
    String methodName = "checkCommitmentNumber";
    startProcedure(getClass().getName(), methodName);

    String retReceivableNum = null;

    // �r���[�E�I�u�W�F�N�g�̎擾
    Xx03CheckCommitmentNumberVOImpl checkVo = getXx03CheckCommitmentNumberVO1();
    checkVo.initQuery(commitmentNumber);

    if (checkVo.getRowCount() > 0)
    {
      // �`�F�b�N�ΏۑO��[���`�[���g�p���Ă���`�[������
      Xx03CheckCommitmentNumberVORowImpl checkRow = (Xx03CheckCommitmentNumberVORowImpl)checkVo.first();
      retReceivableNum = checkRow.getReceivableNum();
      if (retReceivableNum.equals(receivableNum))
      {
        // �Y�����R�[�h�͎����R�[�h
        retReceivableNum = null;
      }
    }

    // �I������
    endProcedure(getClass().getName(), methodName);
    return retReceivableNum;
  } // checkCommitmentNumber

  /**
   * ��ʋ��z�\���t�H�[�}�b�g
   * @param �Ȃ�
   * @return �Ȃ�
   */
  public void formatAmount()
  {
    // ����������
    String methodName = "formatAmount";
    startProcedure(getClass().getName(), methodName);
    
    RowSetIterator selectHeaderIter = null;     
    int fetchedHeaderRowCount;
    String retStr = "N";  // �O����\���敪

    try
    {
      OAViewObject headerVo = getXx03ReceivableSlipsVO1();
      Xx03ReceivableSlipsVORowImpl headerRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedHeaderRowCount = headerVo.getFetchedRowCount();
      fetchedHeaderRowCount = headerVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectHeaderIter = headerVo.createRowSetIterator("selectHeaderIter");
      Xx03GetBaseCurrencyVOImpl baseCurVo = getXx03GetBaseCurrencyVO1();
      baseCurVo.executeQuery();
      Xx03GetBaseCurrencyVORowImpl baseCurRow = (Xx03GetBaseCurrencyVORowImpl)baseCurVo.first();

      if (fetchedHeaderRowCount > 0)
      {
        selectHeaderIter.setRangeStart(0);
        selectHeaderIter.setRangeSize(fetchedHeaderRowCount);

        headerRow = (Xx03ReceivableSlipsVORowImpl)selectHeaderIter.first();

        if (headerRow != null){

          //ver 11.5.10.2.10B Add Start
          XX03GetItemFormatVOImpl    formatVo  = getXX03GetItemFormatVO1();
          XX03GetItemFormatVORowImpl formatRow = null;
          //ver 11.5.10.2.10B Add End

          // �ʉ݃R�[�h�擾
          String curCode = headerRow.getInvoiceCurrencyCode();  // �I�𒆒ʉ݃R�[�h
          String baseCurCode = baseCurRow.getCurrencyCode();    // �@�\�ʉ݃R�[�h

          // �������v���z�t�H�[�}�b�g
          //ver 11.5.10.2.10B Chg Start
          //String strInvAmount = 
          //  getFormatCurrencyString(headerRow.getInvAmount(), curCode);
          //headerRow.setDispInvAmount(strInvAmount);
          formatVo.initQuery(curCode, headerRow.getInvAmount());
          formatRow = (XX03GetItemFormatVORowImpl)formatVo.first();
          headerRow.setDispInvAmount(formatRow.getFormatItem());
          //ver 11.5.10.2.10B Chg End

          //ver 11.5.10.2.10B Chg Start
          // ���Z�ύ��v���z�t�H�[�}�b�g
          //String strInvAccountedAmount = 
          //  getFormatCurrencyString(headerRow.getInvAccountedAmount(), baseCurCode);
          //headerRow.setDispInvAccountedAmount(strInvAccountedAmount);
          formatVo.initQuery(baseCurCode, headerRow.getInvAccountedAmount());
          formatRow = (XX03GetItemFormatVORowImpl)formatVo.first();
          headerRow.setDispInvAccountedAmount(formatRow.getFormatItem());
          //ver 11.5.10.2.10B Chg End

          //ver 11.5.10.2.10B Chg Start
          // �{�̍��v���z�t�H�[�}�b�g
          //String strInvItemAmount = 
          //  getFormatCurrencyString(headerRow.getInvItemAmount(), curCode);
          //headerRow.setDispInvItemAmount(strInvItemAmount);
          formatVo.initQuery(curCode, headerRow.getInvItemAmount());
          formatRow = (XX03GetItemFormatVORowImpl)formatVo.first();
          headerRow.setDispInvItemAmount(formatRow.getFormatItem());
          //ver 11.5.10.2.10B Chg End

          //ver 11.5.10.2.10B Chg Start
          // ����ō��v���z�t�H�[�}�b�g
          //String strInvTaxAmount = 
          //  getFormatCurrencyString(headerRow.getInvTaxAmount(), curCode);
          //headerRow.setDispInvTaxAmount(strInvTaxAmount);
          formatVo.initQuery(curCode, headerRow.getInvTaxAmount());
          formatRow = (XX03GetItemFormatVORowImpl)formatVo.first();
          headerRow.setDispInvTaxAmount(formatRow.getFormatItem());
          //ver 11.5.10.2.10B Chg End

          //ver 11.5.10.2.10B Chg Start
          // �[�����z�t�H�[�}�b�g
          //String strInvPrepayAmount = 
          //  getFormatCurrencyString(headerRow.getInvPrepayAmount(), curCode);
          //headerRow.setDispInvPrepayAmount(strInvPrepayAmount);
          formatVo.initQuery(curCode, headerRow.getInvPrepayAmount());
          formatRow = (XX03GetItemFormatVORowImpl)formatVo.first();
          headerRow.setDispInvPrepayAmount(formatRow.getFormatItem());
          //ver 11.5.10.2.10B Chg End

        } // headerRow
      } // fetchedHeaderRocCount
      else
      {
        // �G���[�E���b�Z�[�W
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);        
      } // fetchedHeaderRowCount 
      
      // �I������
      endProcedure(getClass().getName(), methodName);
    }
    finally
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();
      }
    }
  } // formatAmount

  /**
   * ���z�t�H�[�}�b�g
   * @param numAmount �t�H�[�}�b�g�Ώۋ��z
   * @param currencyCode �t�H�[�}�b�g�ʉ݃R�[�h
   * @return �t�H�[�}�b�g�ϕ�����
   */
  public String getFormatCurrencyString(Number numAmount, String currencyCode)
  {
    // ����������
    String methodName = "getFormatCurrencyString";
    startProcedure(getClass().getName(), methodName);
    
    String strAmount = null;  // Return�p������

    if (numAmount != null || currencyCode != null)
    {
      // �p�����[�^Null�ȊO�̎��̂݃`�F�b�N
      try
      {
        strAmount = numAmount.toString();

        // OANLSServices�擾
        OADBTransaction transaction = getOADBTransaction();
        OANLSServices nlsService = new OANLSServices(transaction);
        // ���z�t�H�[�}�b�g
        strAmount = nlsService.formatCurrency(numAmount, currencyCode); 
      }
      catch (SQLException sqlex)
      {
        throw new OAException(sqlex.getMessage());
      }
    }
    
    // �I������
    endProcedure(getClass().getName(), methodName);
    return strAmount;
  } // getFormatCurrencyString

  /**
   * AFF,DFF�v�����v�g�擾(AR������́A���͉��)
   * @param �Ȃ�
   * @return AFF�v�����v�g
   */
  public ArrayList getAFFPromptArInput()
  {
    // ����������
    String methodName = "getAFFPromptArInput";
    startProcedure(getClass().getName(), methodName);

    ArrayList returnInfo = new ArrayList();

    String segment1Prompt = null;
    String segment2Prompt = null;
    String segment3Prompt = null;
    String segment4Prompt = null;
    String segment5Prompt = null;
    String segment6Prompt = null;
    String segment7Prompt = null;
    String segment8Prompt = null;
    String attribute1Prompt = null;
    String attribute2Prompt = null;

    // AFF�v�����v�g�擾
    Xx03GetAffPromptVOImpl affVo = getXx03GetAffPromptVO1();
    Xx03GetAffPromptVORowImpl affRow = null;
    affVo.executeQuery();
    affRow = (Xx03GetAffPromptVORowImpl)affVo.first();
    if (affRow != null)
    {
      segment1Prompt = affRow.getSegment1Prompt();
      segment2Prompt = affRow.getSegment2Prompt();
      segment3Prompt = affRow.getSegment3Prompt();
      segment4Prompt = affRow.getSegment4Prompt();
      segment5Prompt = affRow.getSegment5Prompt();
      segment6Prompt = affRow.getSegment6Prompt();
      segment7Prompt = affRow.getSegment7Prompt();
      segment8Prompt = affRow.getSegment8Prompt();
    }
    returnInfo.add(segment1Prompt);
    returnInfo.add(segment2Prompt);
    returnInfo.add(segment3Prompt);
    returnInfo.add(segment4Prompt);
    returnInfo.add(segment5Prompt);
    returnInfo.add(segment6Prompt);
    returnInfo.add(segment7Prompt);
    returnInfo.add(segment8Prompt);

    // DFF�v�����v�g�擾
    // �I���O���̎擾
    String orgName = getOrgname();
    Xx03GetDffPromptVOImpl dffVo = getXx03GetDffPromptVO1();
    Xx03GetDffPromptVORowImpl dffRow = null;
    dffVo.initQuery(Xx03ArCommonUtil.DFF_PROMPT_DFF_NAME,
                      orgName,
                      Xx03ArCommonUtil.DFF_PROMPT_ATTRIBUTE1,
                      Xx03ArCommonUtil.DFF_PROMPT_ATTRIBUTE2);
    dffRow = (Xx03GetDffPromptVORowImpl)dffVo.first();
    if (dffRow != null)
    {
      attribute1Prompt = dffRow.getAttribute1Prompt();
      attribute2Prompt = dffRow.getAttribute2Prompt();
    }
    returnInfo.add(attribute1Prompt);
    returnInfo.add(attribute2Prompt);
    
    // �I������
    endProcedure(getClass().getName(), methodName);    
    return returnInfo;
  } // getAFFPromptArInput()

  // ver 1.2 Add Start ���Ńt���O��ŃR�[�h����擾
  /**
   * ���Ńt���O�擾
   * @param �ŃR�[�h
   * @return ���Ńt���O
   */
  //Ver11.5.10.1.6E 2005/12/26 Change Start
//  public String getIncludesTaxFlag(String taxCode)
  public String getIncludesTaxFlag(String taxCode, Date invDate)
  //Ver11.5.10.1.6E 2005/12/26 Change End
  {
    // ����������
    String methodName = "getIncludesTaxFlag";
    startProcedure(getClass().getName(), methodName);
    
    // �r���[�E�I�u�W�F�N�g�̎擾
    Xx03TaxClassLovVOImpl vo = getXx03TaxClassLovVO1();
    //Ver11.5.10.1.6E 2005/12/26 Change Start
    //vo.initQuery(taxCode);
    //vo.first();
    //Xx03TaxClassLovVORowImpl row = (Xx03TaxClassLovVORowImpl)vo.getCurrentRow();
    //String retStr = row.getAmountIncludesTaxFlag();
    String retStr = "";
    vo.initQuery(taxCode, invDate);
    if (vo.first() != null)
    {
      Xx03TaxClassLovVORowImpl row = (Xx03TaxClassLovVORowImpl)vo.getCurrentRow();
      retStr = row.getAmountIncludesTaxFlag();
    }
    //Ver11.5.10.1.6E 2005/12/26 Change End    
    // �I������
    endProcedure(getClass().getName(), methodName);    
    return retStr;
  } // getIncludesTaxFlag()

  //Ver11.5.10.1.6P Chg Start
  /**
   * ��ID�擾
   * @param  �ŃR�[�h
   * @param  ���������t
   * @return ��ID
   */
  public Number getTaxId(String taxCode, Date invDate)
  {
    // ����������
    String methodName = "getTaxId";
    startProcedure(getClass().getName(), methodName);
    
    // �r���[�E�I�u�W�F�N�g�̎擾
    Xx03TaxClassLovVOImpl vo = getXx03TaxClassLovVO1();
    Number retNum = null;
    vo.initQuery(taxCode, invDate);
    if (vo.first() != null)
    {
      Xx03TaxClassLovVORowImpl row = (Xx03TaxClassLovVORowImpl)vo.getCurrentRow();
      retNum = row.getVatTaxId();
    }
    // �I������
    endProcedure(getClass().getName(), methodName);    
    return retNum;
  } // getTaxId()
  //Ver11.5.10.1.6P Chg End

  /**
   * ���Ńt���O�ݒ�
   * @param �Ȃ�
   * @return �Ȃ�
   */
  public void setIncludesTaxFlag()
  {
    // ����������
    String methodName = "setIncludesTaxFlag";
    startProcedure(getClass().getName(), methodName);  
    
    RowSetIterator selectIter = null;
    int fetchedRowCount;
    int rowCount;

    //Ver11.5.10.1.6E 2005/12/26 Add Start
    Date headInvDate = null;
    //Ver11.5.10.1.6E 2005/12/26 Add End

    try
    {
      // �r���[�E�I�u�W�F�N�g�̎擾
      //Ver11.5.10.1.6E 2005/12/26 Add Start
      OAViewObject headerVo = getXx03ReceivableSlipsVO1();
      if (headerVo == null)
      {
        // �G���[�E���b�Z�[�W
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13035", tokens);
      }

      Xx03ReceivableSlipsVORowImpl headerRow = null;
      headerRow = (Xx03ReceivableSlipsVORowImpl)headerVo.getCurrentRow();
      headInvDate = headerRow.getInvoiceDate();
      //Ver11.5.10.1.6E 2005/12/26 Add End
      OAViewObject lineVo = getXx03ReceivableSlipsLineVO1();
      if (lineVo == null)
      {
        // �G���[�E���b�Z�[�W
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsLineVO1")};
        throw new OAException("XX03", "APP-XX03-13035", tokens);
      }
    
      Xx03ReceivableSlipsLineVORowImpl lineRow = null;

      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedRowCount = lineVo.getFetchedRowCount();
      fetchedRowCount = lineVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End

      selectIter = lineVo.createRowSetIterator("selectIter");

      if (fetchedRowCount > 0)
      {
        selectIter.setRangeStart(0);
        selectIter.setRangeSize(fetchedRowCount);

        for (int i=0; i<fetchedRowCount; i++)
        {
          lineRow = (Xx03ReceivableSlipsLineVORowImpl)selectIter.getRowAtRangeIndex(i);

          if ((lineRow != null) &&
              ((lineRow.getTaxCode() != null) && (!"".equals(lineRow.getTaxCode().toString()))))
          {
            //Ver11.5.10.1.6E 2005/12/26 Change Start
//            lineRow.setAmountIncludesTaxFlag(getIncludesTaxFlag(lineRow.getTaxCode()));
            lineRow.setAmountIncludesTaxFlag(getIncludesTaxFlag(lineRow.getTaxCode(),headInvDate));
            //Ver11.5.10.1.6E 2005/12/26 Change End
            //Ver11.5.10.1.6P Add Start
            lineRow.setTaxId(getTaxId(lineRow.getTaxCode(),headInvDate));
            //Ver11.5.10.1.6P Add End
          } // lineRow != null
        } // for loop
      } // fetchedRowCount > 0

      // �I������
      endProcedure(getClass().getName(), methodName);
    }
    finally
    {
      if(selectIter != null)
      {
        selectIter.closeRowSetIterator();
      }
    }
  } // setIncludesTaxFlag()
// ver 1.2 Add End 

  // **************************************************************
  // �m�F��ʂŎg�p���郁�\�b�h
  // **************************************************************

  /**
   * �E�Ӄ��x���v���t�@�C�����擾����
   * @return String �v���t�@�C���E�I�v�V�����l
   */
  public String getRespLevel()
  {
    // ����������
    String methodName = "getRespLevel";
    startProcedure(getClass().getName(), methodName);
    
    OADBTransaction transaction = getOADBTransaction();
    transaction.changeResponsibility(transaction.getResponsibilityId(),
      transaction.getResponsibilityApplicationId());
    String profileOption = transaction.getProfile("XX03_SLIP_AUTHORITIES");

    // �I������
    endProcedure(getClass().getName(), methodName);
    return profileOption;
  }

  // Ver11.5.10.1.6D Add Start
  /**
   * �E�Ӄ��x���v���t�@�C��(�o�����F���W���[��)���擾����
   * @return String �v���t�@�C���E�I�v�V�����l
   */
  public String getAccAppMod()
  {
    OADBTransaction transaction = getOADBTransaction();
    transaction.changeResponsibility( transaction.getResponsibilityId()
                                     ,transaction.getResponsibilityApplicationId());
    String profileOption = transaction.getProfile("XX03_SLIP_ACC_APPROVE_MODULE");
    if ((profileOption == null) || "".equals(profileOption))
    {
      profileOption = "ALL";
    }

    return profileOption;
  }
  // Ver11.5.10.1.6D Add End
  
  /**
   * ���F�K�w�N���X���擾����
   * @param receivableId �����ԍ�
   * @param executeQuery 
   * @return String ���F�K�w�N���X�l
   */
  public String getRecognitionClass(Number receivableId, Boolean executeQuery)
  {
    // ����������
    String methodName = "getRecognitionClass";
    startProcedure(getClass().getName(), methodName);
    
    String retValue = null;
    Number recognitionClass;
    if (receivableId != null)
    {
    
      // �m�肵�Ă���x���`�[�w�b�_���擾����
      Xx03ReceivableSlipsVOImpl hVo = getXx03ReceivableSlipsVO1();
      hVo.initQuery(receivableId, executeQuery);
      hVo.first();
      Xx03ReceivableSlipsVORowImpl row =
        (Xx03ReceivableSlipsVORowImpl)hVo.getCurrentRow();
      recognitionClass = row.getRecognitionClass();
      if(recognitionClass != null)
      {
        retValue = recognitionClass.toString();
      }
    }
    
    // �I������
    endProcedure(getClass().getName(), methodName);
    return retValue;
  }

  /**
   *
   * �o���C���t���O��ON
   */
  public void setAccountRevision()
  {
    // ����������
    String methodName = "setAccountRevision";
    startProcedure(getClass().getName(), methodName);

    // �r���[�E�I�u�W�F�N�g�̎擾
    OAViewObject headerVo = getXx03ReceivableSlipsVO1();
    Xx03ReceivableSlipsVORowImpl headerRow = null;

    headerVo.first();
    headerRow = (Xx03ReceivableSlipsVORowImpl)headerVo.getCurrentRow();

    headerRow.setAccountRevisionFlag(Xx03ArCommonUtil.STR_YES);

    // �I������
    endProcedure(getClass().getName(), methodName);
  } // setAccountRevision

  /**
   *
   * �o���C���ꎞ�t���O��ON
   */
  public void setAccountRevisionTemp()
  {
    // ����������
    String methodName = "setAccountRevision";
    startProcedure(getClass().getName(), methodName);

    // �r���[�E�I�u�W�F�N�g�̎擾
    OAViewObject headerVo = getXx03ReceivableSlipsVO1();
    Xx03ReceivableSlipsVORowImpl headerRow = null;

    headerVo.first();
    headerRow = (Xx03ReceivableSlipsVORowImpl)headerVo.getCurrentRow();

    headerRow.setAccountRevisionFlag("T");

    // �I������
    endProcedure(getClass().getName(), methodName);
  } // setAccountRevision

  /**
   * �ꌩ�ڋq�敪�擾
   * @param �Ȃ�
   * @return �ꌩ�ڋq�敪
   */
  public String getFirstCustomerFlag()
  {
    // ����������
    String methodName = "getFirstCustomerFlag";
    startProcedure(getClass().getName(), methodName);
    String returnStr = "N";

    // �r���[�E�I�u�W�F�N�g�̎擾
    OAViewObject headerVo = getXx03ReceivableSlipsVO1();
    Xx03ReceivableSlipsVORowImpl headerRow = null;

    headerRow = (Xx03ReceivableSlipsVORowImpl)headerVo.first();

    if (headerRow != null)
    {
      returnStr = headerRow.getFirstCustomerFlag(); 
    }

    // �I������
    endProcedure(getClass().getName(), methodName);
    return returnStr;
  } // getFirstCustomerFlag

  /**
   * �`�[�R�s�[
   */
  public Number copy()
  {
    // ����������
    String methodName = "copy";
    startProcedure(getClass().getName(), methodName);

    // �ϐ�    
    RowSetIterator selectHeaderIter = null;
    RowSetIterator selectLineIter = null;    
    int fetchedHeaderRowCount;
    int fetchedLineRowCount;
    Xx03ReceivableSlipsVORowImpl headerRow = null;
    Xx03ReceivableSlipsLineVORowImpl lineRow = null;
    Xx03ReceivableSlipsVORowImpl newHeaderRow = null;
    Row newLineRow = null;
    Number returnReceivableId = null;

    try
    {
      // �r���[�E�I�u�W�F�N�g�̎擾
      OAViewObject headerVo = getXx03ReceivableSlipsVO1();      
      OAViewObject lineVo = getXx03ReceivableSlipsLineVO1();

      //Ver11.5.10.1.4D 2005/08/10 Modify Start
      //fetchedHeaderRowCount = headerVo.getFetchedRowCount();
      //fetchedLineRowCount = lineVo.getFetchedRowCount();
      fetchedHeaderRowCount = headerVo.getRowCount();
      fetchedLineRowCount = lineVo.getRowCount();
      //Ver11.5.10.1.4D 2005/08/10 Modify End
      
      Row[] tempLineRow = new Row[fetchedLineRowCount];
      
      selectHeaderIter = headerVo.createRowSetIterator("selectHeaderIter");
      selectLineIter = lineVo.createRowSetIterator("selectLineIter");

      if ((fetchedHeaderRowCount != 1)
        && (fetchedLineRowCount <= 0))
      {
        // �V�X�e���G���[
        throw new OAException("XX03",
                              "APP-XX03-13008",
                              null,
                              OAException.ERROR,
                              null);          
      }
          
      // �w�b�_�[�̃R�s�[
      headerRow = (Xx03ReceivableSlipsVORowImpl)selectHeaderIter.first();
      if (headerRow != null)
      {
        // ���̕��@�ł́AlinedrRow��null�ƂȂ�B
        newHeaderRow = (Xx03ReceivableSlipsVORowImpl)headerVo.createRow();
        copyHeaderRow(headerRow, newHeaderRow);

        // ���ׂ̃R�s�[
        selectLineIter.setRangeStart(0);
        selectLineIter.setRangeSize(fetchedLineRowCount);

        for (int i=0; i<fetchedLineRowCount; i++)
        {
          lineRow = (Xx03ReceivableSlipsLineVORowImpl)selectLineIter.getRowAtRangeIndex(i);

          if (lineRow != null)
          {
            tempLineRow[i] = lineVo.createAndInitRow(lineRow);
            tempLineRow[i].setAttribute("LineNumber", new Number(i+1));
          }
        } // for loop

        // ����headerRow�̃N���A
        headerRow.removeFromCollection();
        // headerRow.revert();
        headerVo.insertRow(newHeaderRow);

        // ���׃R�s�[
        for (int i=0; i<fetchedLineRowCount; i++)
        {
          lineVo.next();

          //Ver11.5.10.1.6M Change Start
          try
          {
            newLineRow = lineVo.createRow();
            copyLineRow(tempLineRow[i], newLineRow);
            lineVo.insertRow(newLineRow);
          }
          catch(Exception e) 
          {
            newLineRow.remove();
            throw OAException.wrapperException(e);
          }
          //Ver11.5.10.1.6M Change End

          tempLineRow[i].remove();
        }

        returnReceivableId = newHeaderRow.getReceivableId();
      }
    } // try
    catch(Exception ex)
    {
      // debug
      ex.printStackTrace();
      // �V�X�e���G���[
      throw new OAException("XX03",
                            "APP-XX03-13008",
                            null,
                            OAException.ERROR,
                            null);             
    }
    finally
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();
      }
      if(selectLineIter != null)
      {
        selectLineIter.closeRowSetIterator();   
      }
    }
 
    // �I������
    endProcedure(getClass().getName(), methodName);
    return returnReceivableId;

  } // copy()

  /**
   * �w�b�_�[�E�R�s�[
   */
  public void copyHeaderRow(Row fromRow, 
                            Row toRow)
  {
    // ����������
    String methodName = "copyHeaderRow";
    startProcedure(getClass().getName(), methodName);

    for (int i=0; i<Xx03ArCommonUtil.COPY_COL_HEADER.length; i++)
    {
      String attrName = Xx03ArCommonUtil.COPY_COL_HEADER[i];

      Object attrVal = fromRow.getAttribute(attrName);

      if (attrVal != null)
      {
        toRow.setAttribute(attrName ,attrVal);          
      }
    }
    //2005.04.15 add start Ver11.5.10.1      
    Object prepay = fromRow.getAttribute("CommitmentDateFrom");
    if(prepay != null)
    {
      // �O����̗L�������R�s�[
      // �L����(��)�̓V�X�e�����t�A�L����(��)�̓u�����N�Ƃ���
      OADBTransaction txn = getOADBTransaction();
      Date sysDate = new Date(txn.getCurrentDBDate().dateValue());
      // �L����(��)
      if(sysDate != null)
      {
        toRow.setAttribute("CommitmentDateFrom" ,sysDate);
      }              
    }      
    //2005.04.15 add end Ver11.5.10.1

    // �I������
    endProcedure(getClass().getName(), methodName);

  } // copyHeaderRow

  /**
   * ���׃R�s�[
   */
  public void copyLineRow(Row fromRow, 
                            Row toRow)
  {
    // ����������
    String methodName = "copyLineRow";
    startProcedure(getClass().getName(), methodName);  

    for (int i=0; i<Xx03ArCommonUtil.COPY_COL_LINE.length; i++)
    {
      String attrName = Xx03ArCommonUtil.COPY_COL_LINE[i];

      Object attrVal = fromRow.getAttribute(attrName);

      if (attrVal != null)
      {
        toRow.setAttribute(attrName ,attrVal);          
      }
    }
    
    // �I������
    endProcedure(getClass().getName(), methodName);

  } // copyLineRow

  /**
   * �������^�C�v���擾
   * @param transTypeId ����^�C�vID
   * @return �������^�C�v���
   */
  public Hashtable getCreditMemoTypeInfo(Number transTypeId)
  {
    // ����������
    String methodName = "getCreditMemoTypeInfo";
    startProcedure(getClass().getName(), methodName);
    Hashtable returnHashTable = new Hashtable();

    // �r���[�E�I�u�W�F�N�g�̎擾
    Xx03GetCreditTransTypeInfoVOImpl creditVo = getXx03GetCreditTransTypeInfoVO1();
    creditVo.initQuery(transTypeId);
    Xx03GetCreditTransTypeInfoVORowImpl creditRow = (Xx03GetCreditTransTypeInfoVORowImpl)creditVo.first();
    if (creditRow != null)
    {
      // �N���W�b�g�E�����^�C�v���擾
      returnHashTable.put("creditTypeId", creditRow.getCustTrxTypeId());
      returnHashTable.put("creditTypeName", creditRow.getName());
    }
    else
    {
      // �N���W�b�g�E�����^�C�v��`�Ȃ�
      throw new OAException("XX03",
                            "APP-XX03-14062",
                            null,
                            OAException.ERROR,
                            null);
    }

    // �I������
    endProcedure(getClass().getName(), methodName);
    return returnHashTable;
  } // getCreditMemoTypeInfo

  // **************************************************************
  // PL/SQL�p�b�P�[�W�̊֐����g�p���郁�\�b�h
  // **************************************************************

  /**
   * �x���\����Z�o�֐��̌ďo
   * @param termsId �x������ID
   * @param invoice ���������t
   * @return Date �x���\���
   */
  public Date calcDueDate(Number termsId, Date invoiceDate)  {
    OADBTransaction txn = getOADBTransaction();
    Date dueDate = null; // �߂�l
    MessageToken msg= null;
    OAException excep = null;
    
    // ���sSQL�u���b�N
    CallableStatement state =
      txn.createCallableStatement(
        "begin XX03_DEPTINPUT_AR_CHECK_PKG.GET_TERMS_DATE" + 
        "(:1, :2, :3, :4, :5, :6); end;", 0);

    try
    {
      state.setLong(1, termsId.longValue());
      state.setDate(2, (java.sql.Date)invoiceDate.dateValue());
      state.registerOutParameter(3, Types.DATE);
      state.registerOutParameter(4, Types.VARCHAR);
      state.registerOutParameter(5, Types.VARCHAR);
      state.registerOutParameter(6, Types.VARCHAR);

      state.execute();

      dueDate = new Date(state.getDate(3));
      String retCode = state.getString(5);
      String errBuf = state.getString(4);
      
      state.close();

      // ����I��
      if (Xx03ArCommonUtil.SUCCESS.equals(retCode))
      {
        return dueDate;
      }
      // �G���[
      else
      {
        return null;
      }
    }
    catch (SQLException sqlex)
    {
      throw new OAException(sqlex.getMessage());
    }
    finally
    {
      try
      {
        state.close();
      }
      catch (SQLException ex)
      {
        throw OAException.wrapperException(ex);    
      }
    }
  } // calcDueDate()

  /**
   * �d��`�F�b�N�֐��̌ďo
   * @param receivableId �����ԍ�
   * @return Vector �G���[�E���b�Z�[�W
   */
  public Vector callDeptInputAr(Number receivableId)  {
    // ����������
    String methodName = "callDeptInputAr";
    startProcedure(getClass().getName(), methodName);

    Vector exceptions = new Vector(); // �߂�l
    CallableStatement state = null;

    try
    {
      OADBTransaction txn = getOADBTransaction();
      MessageToken token = null;
      OAException msg = null;

      // ���sSQL�u���b�N
      state = txn.createCallableStatement(
        //ver11.5.10.1.6O Chg Start
        //"begin XX03_DEPTINPUT_AR_CHECK_PKG.CHECK_DEPTINPUT_AR" + 
        "begin XX03_DEPTINPUT_AR_CHECK_PKG.CHECK_DEPTINPUT_AR_INPUT" + 
        //ver11.5.10.1.6O Chg End
        "(:1, :2, :3, :4, :5, :6, :7, :8, :9, :10, :11, :12, :13, " +
        ":14, :15, :16, :17, :18, :19, :20, :21, :22, :23, :24, :25, " +
        ":26, :27, :28, :29, :30, :31, :32, :33, :34, :35, :36, :37, " +
        ":38, :39, :40, :41, :42, :43, :44, :45, :46); end;", 0);

      state.setLong(1, receivableId.longValue());
      state.registerOutParameter(2, Types.INTEGER);
      state.registerOutParameter(3, Types.VARCHAR);
      state.registerOutParameter(4, Types.VARCHAR);
      state.registerOutParameter(5, Types.VARCHAR);
      state.registerOutParameter(6, Types.VARCHAR);
      state.registerOutParameter(7, Types.VARCHAR);
      state.registerOutParameter(8, Types.VARCHAR);
      state.registerOutParameter(9, Types.VARCHAR);
      state.registerOutParameter(10, Types.VARCHAR);
      state.registerOutParameter(11, Types.VARCHAR);
      state.registerOutParameter(12, Types.VARCHAR);
      state.registerOutParameter(13, Types.VARCHAR);
      state.registerOutParameter(14, Types.VARCHAR);
      state.registerOutParameter(15, Types.VARCHAR);
      state.registerOutParameter(16, Types.VARCHAR);
      state.registerOutParameter(17, Types.VARCHAR);
      state.registerOutParameter(18, Types.VARCHAR);
      state.registerOutParameter(19, Types.VARCHAR);
      state.registerOutParameter(20, Types.VARCHAR);
      state.registerOutParameter(21, Types.VARCHAR);
      state.registerOutParameter(22, Types.VARCHAR);
      state.registerOutParameter(23, Types.VARCHAR);
      state.registerOutParameter(24, Types.VARCHAR);
      state.registerOutParameter(25, Types.VARCHAR);
      state.registerOutParameter(26, Types.VARCHAR);
      state.registerOutParameter(27, Types.VARCHAR);
      state.registerOutParameter(28, Types.VARCHAR);
      state.registerOutParameter(29, Types.VARCHAR);
      state.registerOutParameter(30, Types.VARCHAR);
      state.registerOutParameter(31, Types.VARCHAR);
      state.registerOutParameter(32, Types.VARCHAR);
      state.registerOutParameter(33, Types.VARCHAR);
      state.registerOutParameter(34, Types.VARCHAR);
      state.registerOutParameter(35, Types.VARCHAR);
      state.registerOutParameter(36, Types.VARCHAR);
      state.registerOutParameter(37, Types.VARCHAR);
      state.registerOutParameter(38, Types.VARCHAR);
      state.registerOutParameter(39, Types.VARCHAR);
      state.registerOutParameter(40, Types.VARCHAR);
      state.registerOutParameter(41, Types.VARCHAR);
      state.registerOutParameter(42, Types.VARCHAR);
      state.registerOutParameter(43, Types.VARCHAR);
      state.registerOutParameter(44, Types.VARCHAR);
      state.registerOutParameter(45, Types.VARCHAR);
      state.registerOutParameter(46, Types.VARCHAR);

      state.execute();

      String errFlag = state.getString(3);
      int errCnt = new Integer(state.getString(2)).intValue();

      exceptions.addElement(errFlag);

      // ����I���ȊO
      if (!Xx03ArCommonUtil.RETCODE_SUCCESS.equals(errFlag))
      {
        int indexNum = 0;
        byte messageType = OAException.ERROR;
        for (int i = 1; i <= errCnt; i++)
        {
          // �G���[�E���b�Z�[�W�́A5�ڂ̈�������J�n
          indexNum = (3 + i * 2);
          token = new MessageToken("TOK_XX03_CHECK_ERROR",
                                   state.getString(indexNum));
          // �x��
          if (Xx03ArCommonUtil.RETCODE_WARNING.equals(errFlag))
          {
            messageType = OAException.WARNING;
          }

          msg = new OAException("XX03",
                                "APP-XX03-14101",
                                new MessageToken[]{token},
                                messageType,
                                null);

          exceptions.addElement(msg);

          token = null;
          msg   = null;
          
          //Ver11.5.10.1.6H 2005/12/28 Add Start
          // �G���[������20���𒴂����ꍇ�A�G���[���b�Z�[�W�\���͏I������
          if (20 <= i)
          {
            i = errCnt + 1;
          }
          //Ver11.5.10.1.6H 2005/12/28 Add End
          
        }
      }
    }
    catch(SQLException ex)
    {
      throw new OAException(ex.getMessage());
    }
    catch(OAException ex)
    {
      throw OAException.wrapperException(ex);
    }
    finally
    {
      try{
        state.close();
      }
      catch(SQLException ex)
      {
        throw OAException.wrapperException(ex);
      }
    }

    // �I������
    endProcedure(getClass().getName(), methodName);
    return exceptions;
  } // callDeptInputAr

  /**
   * ���[�N�t���[�֐��̌ďo(�\��)
   * @param
   * @return �`�[�ԍ�
   */
  public String startDivProcess()
  {
    // ����������
    String methodName = "startDivProcess";
    startProcedure(getClass().getName(), methodName);

    String errMsg = null;
    Hashtable returnHashtable = null;
    String retReceivableNum = null;
    
    RowSetIterator selectHeaderIter = null;
    int fetchedHeaderRowCount;

    //ver11.5.10.1.6 Add Start
    RowSetIterator selectUpdIter = null;
    int fetchedUpdRowCount;
    //ver11.5.10.1.6 Add End

    try
    {
      // �r���[�E�I�u�W�F�N�g�̎擾
      //ver11.5.10.1.6 Chg Start
      //OAViewObject headerVo = getXx03ReceivableSlipsVO1();
      OAViewObject headerVo = getXx03ConfirmDispSlipsVO1();
      //ver11.5.10.1.6 Chg Start

      if (headerVo == null)
      {
        // �G���[�E���b�Z�[�W
        //ver11.5.10.1.6 Chg Start
        //MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ConfirmDispSlipsVO1")};
        //ver11.5.10.1.6 Chg End
        throw new OAException("XX03", "APP-XX03-13035", tokens);
      }

      //ver11.5.10.1.6 Add Start
      OAViewObject updVo = getXx03ConfirmUpdSlipsVO1();
      if (updVo == null)
      {
        // �G���[�E���b�Z�[�W
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ConfirmUpdSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13035", tokens);
      }
      //ver11.5.10.1.6 Add End

      //ver11.5.10.1.6 Chg Start
      //Xx03ReceivableSlipsVORowImpl headerRow = null;
      Xx03ConfirmDispSlipsVORowImpl headerRow = null;
      Xx03ConfirmUpdSlipsVORowImpl  updRow    = null;
      //ver11.5.10.1.6 Chg End
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedHeaderRowCount = headerVo.getFetchedRowCount();
      fetchedHeaderRowCount = headerVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectHeaderIter      = headerVo.createRowSetIterator("selectHeaderIter");

      //ver11.5.10.1.6 Add Start
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedUpdRowCount    = updVo.getFetchedRowCount();
      fetchedUpdRowCount    = updVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectUpdIter         = updVo.createRowSetIterator("selectUpdIter");
      //ver11.5.10.1.6 Add End

      //ver11.5.10.1.6 Chg Start
      //if (fetchedHeaderRowCount > 0)
      if ((fetchedHeaderRowCount > 0) && (fetchedUpdRowCount > 0))
      //ver11.5.10.1.6 Chg End
      {
        selectHeaderIter.setRangeStart(0);
        selectHeaderIter.setRangeSize(fetchedHeaderRowCount);

        //ver11.5.10.1.6 Chg Start
        //headerRow = (Xx03ReceivableSlipsVORowImpl)selectHeaderIter.first();
        headerRow = (Xx03ConfirmDispSlipsVORowImpl)selectHeaderIter.first();
        updRow    = (Xx03ConfirmUpdSlipsVORowImpl)selectUpdIter.first();
        //ver11.5.10.1.6 Chg End

        //ver11.5.10.1.6 Chg Start
        //if (headerRow != null)
        if ((headerRow != null) && (updRow != null))
        //ver11.5.10.1.6 Chg End
        {
          //ver11.5.10.1.6 Chg Start
          //returnHashtable = startDivProcess(headerRow.getReceivableId(),
          //                                   headerRow.getRequestorPersonId(),
          //                                   headerRow.getApproverPersonId());
          returnHashtable = startDivProcess( headerRow.getReceivableId()
                                            ,headerRow.getRequestorPersonId()
                                            ,updRow.getApproverPersonId());
          //ver11.5.10.1.6 Chg End

          errMsg = (String)returnHashtable.get("result");
          retReceivableNum = (String)returnHashtable.get("receivableNum");

          if (!(Xx03ArCommonUtil.SUCCESS.equals(errMsg)))
          {
            throw new OAException(errMsg);
          }
        } // headerRow
      } // fetchedHeaderRocCount
      else
      {
        // �G���[�E���b�Z�[�W
        //ver11.5.10.1.6 Chg Start
        //MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
        //throw new OAException("XX03", "APP-XX03-13034", tokens);
        if (fetchedHeaderRowCount > 0)
        {
          MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ConfirmDispSlipsVO1")};
          throw new OAException("XX03", "APP-XX03-13034", tokens);
        }
        if (fetchedUpdRowCount > 0)
        {
          MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ConfirmUpdSlipsVO1")};
          throw new OAException("XX03", "APP-XX03-13034", tokens);
        }
        //ver11.5.10.1.6 Chg End
      } // fetchedHeaderRowCount

      // �I������
      endProcedure(getClass().getName(), methodName);  
    }
    finally
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();
      }
      //ver11.5.10.1.6 Add Start
      if(selectUpdIter != null)
      {
        selectUpdIter.closeRowSetIterator();
      }
      //ver11.5.10.1.6 Add End
    }
    return retReceivableNum;
  } // startDivProcess

  /**
   * ���[�N�t���[�֐��̌ďo(�\��)
   * @param receivableId �����ԍ�
   * @return String ���b�Z�[�W
   */
  public Hashtable startDivProcess(Number receivableId,
                                Number requestorPersonId,
                                Number approverPersonId)
  {
    OADBTransaction txn = getOADBTransaction();
    Hashtable returnHashTable = new Hashtable();

    // ���sSQL�u���b�N
    CallableStatement state =
      txn.createCallableStatement(
        "begin XX03_AR_ENTRY_WORKFLOW_PKG.START_DIV_PROCESS" + 
        "(:1, :2, :3, :4, :5, :6, :7); end;", 0);

    try
    {
      state.setLong(1, receivableId.longValue());
      state.setLong(2, requestorPersonId.longValue());
      state.setLong(3, approverPersonId.longValue());      
      state.registerOutParameter(4, Types.VARCHAR);    
      state.registerOutParameter(5, Types.VARCHAR);
      state.registerOutParameter(6, Types.VARCHAR);
      state.registerOutParameter(7, Types.VARCHAR);

      state.execute();

      String retCode = state.getString(6);
      String errBuf = state.getString(5);
      String receivableNum = state.getString(4);
      
      state.close();

      // �G���[�Ȃ�
      if (Xx03ArCommonUtil.SUCCESS.equals(retCode))
      {
        // �߂�l�Z�b�g
        returnHashTable.put("result", Xx03ArCommonUtil.SUCCESS);
        returnHashTable.put("receivableNum", receivableNum);
        return returnHashTable;
      }
      // �G���[�Ȃ��A�x������
      else
      {
        returnHashTable.put("result", errBuf);
        returnHashTable.put("receivableNum", "");
        return returnHashTable;
      }
    }
    catch (SQLException sqlex)
    {
      throw new OAException(sqlex.getMessage());      
    }
    finally
    {
      try
      {
        state.close();
      }
      catch (SQLException ex)
      {
        throw OAException.wrapperException(ex);    
      }      
    }
  } // startDivProcess

  /**
   * ���[�N�t���[�֐��̌ďo(���右�F/����۔F)
   * @param receivableId �`�[ID
   * @param requestKey �\���L�[(ItemKey)
   * @param approverPersonId ���F��ID
   * @param answerFlag ���F���ʃt���O(Y/N)
   * @param approverComments ���F�҃R�����g
   * @param nextApproverPersonId ���̏��F�҂̏]�ƈ�ID
   * @return String ���b�Z�[�W
   */
  public String answerDivProposal(Number receivableId,
                                 String requestKey,
                                 Number approverPersonId,
                                 String answerFlag,
                                 String approverComments,
                                 Number nextApproverPersonId)
  {
    OADBTransaction txn = getOADBTransaction();

    // ���sSQL�u���b�N
    CallableStatement state =
      txn.createCallableStatement(
        "begin XX03_AR_ENTRY_WORKFLOW_PKG.ANSWER_DIV_PROPOSAL" + 
        "(:1, :2, :3, :4, :5, :6, :7, :8, :9); end;", 0);

    try
    {
      state.setLong(1, receivableId.longValue());
      state.setString(2, requestKey);
      state.setLong(3, approverPersonId.longValue());
      state.setString(4, answerFlag);

      if (approverComments != null)
      {
        state.setString(5, approverComments);            
      }
      else
      {
        state.setNull(5, Types.VARCHAR);
      }

      if (approverPersonId.compareTo(nextApproverPersonId) != 0)
      {
        state.setLong(6, nextApproverPersonId.longValue());        
      }
      else
      {
        state.setNull(6, Types.INTEGER);        
      }

      state.registerOutParameter(7, Types.VARCHAR);
      state.registerOutParameter(8, Types.VARCHAR);
      state.registerOutParameter(9, Types.VARCHAR);

      state.execute();

      String retCode = state.getString(8);
      String errBuf = state.getString(7);

      state.close();

      // ����I��
      if (Xx03ArCommonUtil.SUCCESS.equals(retCode))
      {
        return Xx03ArCommonUtil.SUCCESS;
      }
      // �G���[
      else
      {
        return errBuf;
      }
    }
    catch (SQLException sqlex)
    {
      throw new OAException(sqlex.getMessage());      
    }
    finally
    {
      try
      {
        state.close();
      }
      catch (SQLException ex)
      {
        throw OAException.wrapperException(ex);    
      }      
    }
  } // answerDivProcess

  /**
   * ���[�N�t���[�֐��̌ďo(�o�����F/�o���۔F)
   * @param answerFlag  �񓚃t���O
   * @param answerId    �񓚎�ID
   * @return
   */
  public void startAccProcess(String answerFlag, Number answerId)
  {
    // ����������
    String methodName = "startAccProcess";
    startProcedure(getClass().getName(), methodName);

    String errMsg = null;
    
    RowSetIterator selectHeaderIter = null;    
    int fetchedHeaderRowCount;
    //ver11.5.10.1.6 Add Start
    RowSetIterator selectUpdIter = null;
    int fetchedUpdRowCount;
    //ver11.5.10.1.6 Add End

    try
    {
      // �r���[�E�I�u�W�F�N�g�̎擾
      //ver11.5.10.1.6 Chg Start
      //OAViewObject headerVo = getXx03ReceivableSlipsVO1();
      //Xx03ReceivableSlipsVORowImpl headerRow = null;
      OAViewObject headerVo = getXx03ConfirmDispSlipsVO1();
      Xx03ConfirmDispSlipsVORowImpl headerRow = null;
      OAViewObject updVo = getXx03ConfirmUpdSlipsVO1();
      Xx03ConfirmUpdSlipsVORowImpl updRow = null;
      //ver11.5.10.1.6 Chg End

      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedHeaderRowCount = headerVo.getFetchedRowCount();
      fetchedHeaderRowCount = headerVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectHeaderIter = headerVo.createRowSetIterator("selectHeaderIter");

      //ver11.5.10.1.6 Add Start
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedUpdRowCount = updVo.getFetchedRowCount();
      fetchedUpdRowCount = updVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectUpdIter = updVo.createRowSetIterator("selectUpdIter");
      //ver11.5.10.1.6 Add End

      //ver11.5.10.1.6 Chg Start
      //if (fetchedHeaderRowCount > 0)
      if ((fetchedHeaderRowCount > 0) && (fetchedUpdRowCount > 0))
      //ver11.5.10.1.6 Chg End
      {
        selectHeaderIter.setRangeStart(0);
        selectHeaderIter.setRangeSize(fetchedHeaderRowCount);

        //ver11.5.10.1.6 Add Start
        selectUpdIter.setRangeStart(0);
        selectUpdIter.setRangeSize(fetchedUpdRowCount);
        //ver11.5.10.1.6 Add End

        //ver11.5.10.1.6 Chg Start
        //headerRow = (Xx03ReceivableSlipsVORowImpl)selectHeaderIter.first();
        headerRow = (Xx03ConfirmDispSlipsVORowImpl)selectHeaderIter.first();
        updRow    = (Xx03ConfirmUpdSlipsVORowImpl)selectUpdIter.first();
        //ver11.5.10.1.6 Chg End

        //ver11.5.10.1.6 Chg Start
        //if (headerRow != null)
        if ((headerRow != null) && (updRow != null))
        //ver11.5.10.1.6 Chg End
        {
          //ver11.5.10.1.6 Chg Start
          //errMsg = startAccProcess(headerRow.getReceivableId(),
          //                         answerId,
          //                         answerFlag,
          //                         headerRow.getApproverComments());
          errMsg = startAccProcess( headerRow.getReceivableId()
                                   ,answerId
                                   ,answerFlag
                                   ,updRow.getApproverComments());
          //ver11.5.10.1.6 Chg End

          if (!(Xx03ArCommonUtil.SUCCESS.equals(errMsg)))
          {
            throw new OAException(errMsg);
          }
        } // headerRow
      } // fetchedHeaderRocCount
      else
      {
        // �G���[�E���b�Z�[�W
        //ver11.5.10.1.6 Chg Start
        //MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
        //throw new OAException("XX03", "APP-XX03-13034", tokens);
        if (fetchedHeaderRowCount > 0)
        {
          MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ConfirmDispSlipsVO1")};
          throw new OAException("XX03", "APP-XX03-13034", tokens);
        }
        if (fetchedUpdRowCount > 0)
        {
          MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ConfirmUpdSlipsVO1")};
          throw new OAException("XX03", "APP-XX03-13034", tokens);
        }
        //ver11.5.10.1.6 Chg End
      } // fetchedHeaderRowCount

      // �I������
      endProcedure(getClass().getName(), methodName);  
    }
    finally
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();
      }
      //ver11.5.10.1.6O Add Start
      if(selectUpdIter != null)
      {
        selectUpdIter.closeRowSetIterator();
      }
      //ver11.5.10.1.6O Add End
    }
  } // startAccProcess

  /**
   * ���[�N�t���[�֐��̌ďo(�o�����F)
   * @param receivableId �����ԍ�
   * @param approverPersonId ���F��ID
   * @param answerFlag ���F��'Y'�^�p����'N'
   * @param approverComments �R�����g
   * @return String ���b�Z�[�W
   */
  public String startAccProcess(Number receivableId,
                                Number approverPersonId,
                                String answerFlag,
                                String approverComments)
  {
    OADBTransaction txn = getOADBTransaction();

    // ���sSQL�u���b�N
    CallableStatement state =
      txn.createCallableStatement(
        "begin XX03_AR_ENTRY_WORKFLOW_PKG.START_ACC_PROCESS" + 
        "(:1, :2, :3, :4, :5, :6, :7); end;", 0);

    try
    {
      state.setLong(1, receivableId.longValue());
      state.setLong(2, approverPersonId.longValue());
      state.setString(3, answerFlag);
      if (approverComments != null)
      {
       state.setString(4, approverComments);            
      }
      else
      {
        state.setNull(4, Types.VARCHAR);
      }
      state.registerOutParameter(5, Types.VARCHAR);
      state.registerOutParameter(6, Types.VARCHAR);
      state.registerOutParameter(7, Types.VARCHAR);

      state.execute();

      String retCode = state.getString(6);
      String errBuf = state.getString(5);

      state.close();

      // ����I��
      if (Xx03ArCommonUtil.SUCCESS.equals(retCode))
      {
        return Xx03ArCommonUtil.SUCCESS;
      }
      // �G���[
      else
      {
        return errBuf;
      }
    }
    catch (SQLException sqlex)
    {
      throw new OAException(sqlex.getMessage());      
    }
    finally
    {
      try
      {
        state.close();
      }
      catch (SQLException ex)
      {
        throw OAException.wrapperException(ex);    
      }      
    }
  } // startAccProcess

  /**
   * ���[�N�t���[�֐��̌ďo(�\�����)
   * @param answerFlag
   * @return
   */
  public void cancelProposal()
  {
    // ����������
    String methodName = "cancelProposal";
    startProcedure(getClass().getName(), methodName);

    String errMsg = null;
    
    RowSetIterator selectHeaderIter = null;
    int fetchedHeaderRowCount;

    //ver11.5.10.1.6 Add Start
    RowSetIterator selectUpdIter = null;
    int fetchedUpdRowCount;
    //ver11.5.10.1.6 Add End

    try
    {
      // �r���[�E�I�u�W�F�N�g�̎擾
      //ver11.5.10.1.6 Chg Start
      //OAViewObject headerVo = getXx03ReceivableSlipsVO1();
      //Xx03ReceivableSlipsVORowImpl headerRow = null;
      OAViewObject headerVo = getXx03ConfirmDispSlipsVO1();
      Xx03ConfirmDispSlipsVORowImpl headerRow = null;
      //ver11.5.10.1.6 Chg End

      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedHeaderRowCount = headerVo.getFetchedRowCount();
      fetchedHeaderRowCount = headerVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectHeaderIter = headerVo.createRowSetIterator("selectHeaderIter");

      //ver11.5.10.1.6 Add Start
      OAViewObject updVo = getXx03ConfirmUpdSlipsVO1();
      Xx03ConfirmUpdSlipsVORowImpl updRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedUpdRowCount = updVo.getFetchedRowCount();
      fetchedUpdRowCount = updVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectUpdIter = updVo.createRowSetIterator("selectUpdIter");
      //ver11.5.10.1.6 Add End

      //ver11.5.10.1.6 Chg Start
      //if (fetchedHeaderRowCount > 0)
      if ((fetchedHeaderRowCount > 0) && (fetchedUpdRowCount > 0))
      //ver11.5.10.1.6 Chg End
      {
        selectHeaderIter.setRangeStart(0);
        selectHeaderIter.setRangeSize(fetchedHeaderRowCount);
        //ver11.5.10.1.6 Add Start
        selectUpdIter.setRangeStart(0);
        selectUpdIter.setRangeSize(fetchedUpdRowCount);
        //ver11.5.10.1.6 Add End

        //ver11.5.10.1.6 Chg Start
        //headerRow = (Xx03ReceivableSlipsVORowImpl)selectHeaderIter.first();
        headerRow = (Xx03ConfirmDispSlipsVORowImpl)selectHeaderIter.first();
        updRow    = (Xx03ConfirmUpdSlipsVORowImpl)selectUpdIter.first();
        //ver11.5.10.1.6 Chg End

        //ver11.5.10.1.6 Chg Start
        //if (headerRow != null)
        if ((headerRow != null) && (updRow != null))
        //ver11.5.10.1.6 Chg End
        {
          errMsg = cancelProposal(headerRow.getReceivableId(),
                                  headerRow.getRequestKey());
         
          if (!(Xx03ArCommonUtil.SUCCESS.equals(errMsg)))
          {
            throw new OAException(errMsg);
          }
        } // headerRow
      } // fetchedHeaderRocCount
      else
      {
        // �G���[�E���b�Z�[�W
        //ver11.5.10.1.6 Chg Start
        //MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
        //throw new OAException("XX03", "APP-XX03-13034", tokens);
        if (fetchedHeaderRowCount > 0)
        {
          MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ConfirmDispSlipsVO1")};
          throw new OAException("XX03", "APP-XX03-13034", tokens);
        }
        if (fetchedUpdRowCount > 0)
        {
          MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ConfirmUpdSlipsVO1")};
          throw new OAException("XX03", "APP-XX03-13034", tokens);
        }
        //ver11.5.10.1.6 Chg End
      } // fetchedHeaderRowCount

      // �I������
      endProcedure(getClass().getName(), methodName);   
    }
    finally
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();        
      }
      //ver11.5.10.1.6 Add Start
      if(selectUpdIter != null)
      {
        selectUpdIter.closeRowSetIterator();
      }
      //ver11.5.10.1.6 Add End
    }   
  } // cancelProposal

  /**
   * ���[�N�t���[�֐��̌ďo(�\�����)
   * @param receivableId �����ԍ�
   * @param requestKey �\���L�[�iWorkFlow�p�j
   * @return String ���b�Z�[�W
   */
  public String cancelProposal(Number receivableId,
                               String requestKey)
  {
    OADBTransaction txn = getOADBTransaction();

    // ���sSQL�u���b�N
    CallableStatement state =
      txn.createCallableStatement(
        "begin XX03_AR_ENTRY_WORKFLOW_PKG.CANCEL_PROPOSAL" + 
        "(:1, :2, :3, :4, :5); end;", 0);

    try
    {
      state.setLong(1, receivableId.longValue());
      state.setString(2, requestKey);

      state.registerOutParameter(3, Types.VARCHAR);
      state.registerOutParameter(4, Types.VARCHAR);
      state.registerOutParameter(5, Types.VARCHAR);

      state.execute();

      String retCode = state.getString(4);
      String errBuf = state.getString(3);
      
      state.close();

      // ����I��
      if (Xx03ArCommonUtil.SUCCESS.equals(retCode))
      {
        return Xx03ArCommonUtil.SUCCESS;
      }
      // �G���[
      else
      {
        return errBuf;
      }
    }
    catch (SQLException sqlEx)
    {
      throw new OAException(sqlEx.getMessage());
    }
    catch (NumberFormatException numEx)
    {
      throw new NumberFormatException(numEx.getMessage());
    }
    finally
    {
      try
      {
        state.close();
      }
      catch (SQLException ex)
      {
        throw OAException.wrapperException(ex);
      }
    }
  } // cancelProposal

  /**
   * �I���O���̎擾
   * @param �Ȃ�
   * @return String �I���O����
   */
  public String getOrgname()
  {
    // 2006/01/23 Ver11.5.10.1.6L Add Start
    OADBTransaction txn = getOADBTransaction();
    // 2006/01/23 Ver11.5.10.1.6L Add End

    // ���sSQL�u���b�N
    CallableStatement state =
      txn.createCallableStatement(
        "begin XX03_BOOKS_ORG_NAME_GET_PKG.ORG_NAME" + 
        "(:1, :2, :3, :4, XX00_PROFILE_PKG.VALUE('ORG_ID')); end;", 0);

    try
    {
      state.registerOutParameter(1, Types.VARCHAR);
      state.registerOutParameter(2, Types.VARCHAR);
      state.registerOutParameter(3, Types.VARCHAR);
      state.registerOutParameter(4, Types.VARCHAR);

      state.execute();

      String retCode = state.getString(2);
      String errBuf = state.getString(1);
      String orgName = state.getString(4);
      
      state.close();

      // ����I��
      if (Xx03ArCommonUtil.SUCCESS.equals(retCode))
      {
        return orgName;
      }
      // �G���[
      else
      {
        // �G���[�E���b�Z�[�W
        // 2006/01/23 Ver11.5.10.1.6L Change Start
        //MessageToken[] tokens = {new MessageToken("OBJECT_NAME", Xx03ArCommonUtil.MESSAGE_STR_ORG_NAME_INFO)};
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", txn.getMessage("XX03","APP-XX03-34067",null))};
        throw new OAException("XX03","APP-XX03-13036", tokens);
        // 2006/01/23 Ver11.5.10.1.6L Change End
      }
    }
    catch (SQLException sqlEx)
    {
      throw new OAException(sqlEx.getMessage());
    }
    finally
    {
      try
      {
        state.close();
      }
      catch (SQLException ex)
      {
        throw OAException.wrapperException(ex);
      }
    }
  } // getOrgname

  // Ver1.4 change start ------------------------------------------------------
  /**
   * �O����L�����`�F�b�N����
   * @return �Ȃ�
   */
  public void checkCommitmentDate()
  {
    String commitmentNumber = null;
    Date startDate = null;
    Date endDate = null;
    Date invoiceDate = null;

    // �r���[�E�I�u�W�F�N�g�̎擾
    Xx03ReceivableSlipsVOImpl headerVo = getXx03ReceivableSlipsVO1();
    Xx03ReceivableSlipsVORowImpl headerRow = null;

    headerVo.first();
    headerRow = (Xx03ReceivableSlipsVORowImpl)headerVo.getCurrentRow();

    // �O��[���`�[�ԍ��̎擾
    commitmentNumber = headerRow.getCommitmentNumber();

    // ���������t�̎擾
    invoiceDate = headerRow.getInvoiceDate();

    // �O��[���`�[�̗L�����̎擾
    // �r���[�E�I�u�W�F�N�g�̎擾
    Xx03CommitmentDateVOImpl vo = getXx03CommitmentDateVO1();
    vo.initQuery(commitmentNumber);
    vo.first();

    Xx03CommitmentDateVORowImpl row = (Xx03CommitmentDateVORowImpl)vo.getCurrentRow();

    // �O����̗L�����擾
    startDate = row.getStartDateCommitment();
    endDate = row.getEndDateCommitment();

    if(endDate == null)
    {
      endDate = invoiceDate;
    }
  
   // �L�����`�F�b�N
    if (startDate != null)
    {
      // �O����̎�(�L����(��)�����͂���Ă��鎞)�̂݃`�F�b�N
      if (endDate != null)
      {
        // �L����(��)�A�L����(��)�������w�肳��Ă��鎞
        if ((invoiceDate.compareTo(startDate) < 0)
            || (invoiceDate.compareTo(endDate) > 0))
          // ���������t < �L����(��) or ���������t > �L����(��)�̎�
          throw new OAException("XX03",
                                "APP-XX03-14065",
                                null,
                                OAException.ERROR,
                                null);
      }
      else
      {
        // �L����(��)�݂̂��w�肳��Ă��鎞
        if (invoiceDate.compareTo(startDate) < 0)
        {
          // ���������t < �L����(��)�̎�
          throw new OAException("XX03",
                                "APP-XX03-14065",
                                null,
                                OAException.ERROR,
                                null);
        }
      }
    }
  } // checkCommitmentDate()

  /**
   * �x�����@�L�����`�F�b�N����
   * @return �Ȃ�
   */
  //ver11.5.10.1.6 Del Start
  //public void checkPaymentDate()
  //{
  //  Date recStartDate = null;
  //  Date recEndDate = null;
  //  Date custStartDate = null;
  //  Date custEndDate = null;
  //  Date invoiceDate = null;

  //  // �r���[�E�I�u�W�F�N�g�̎擾
  //  Xx03ReceivableSlipsVOImpl headerVo = getXx03ReceivableSlipsVO1();
  //  Xx03ReceivableSlipsVORowImpl headerRow = null;

  //  headerVo.first();
  //  headerRow = (Xx03ReceivableSlipsVORowImpl)headerVo.getCurrentRow();

  //  // �x�����@ID�̎擾
  //  Number receiptMethodId = headerRow.getReceiptMethodId();

  //  // ���������t�̎擾
  //  invoiceDate = headerRow.getInvoiceDate();

  //  // �x�����@�̗L�����̎擾(�x�����@�̂ɕR�t���L�����ƌڋq�ɕR�t���L����)
  //  // �r���[�E�I�u�W�F�N�g�̎擾
  //  Xx03PaymentDateVOImpl vo = getXx03PaymentDateVO1();

  //  vo.initQuery(receiptMethodId);

  //  vo.first();

  //  Xx03PaymentDateVORowImpl row = (Xx03PaymentDateVORowImpl)vo.getCurrentRow();

  //  // �x�����@�ɕR�t���L�����擾
  //  recStartDate = row.getRecStartDate();
  //  recEndDate = row.getRecEndDate();

  //  if(recEndDate == null)
  //  {
  //    recEndDate = invoiceDate;
  //  }
    
  //  // �x�����@�ɕR�t���L�����`�F�b�N
  //  if (recStartDate != null)
  //  {
  //    // �x�����@�̗L����(��)�����͂���Ă��鎞)�̂݃`�F�b�N
  //    if (recEndDate != null)
  //    {
  //      // �L����(��)�A�L����(��)�������w�肳��Ă��鎞
  //      if ((invoiceDate.compareTo(recStartDate) < 0)
  //          || (invoiceDate.compareTo(recEndDate) > 0))
  //        // ���������t < �L����(��) or ���������t > �L����(��)�̎�
  //        throw new OAException("XX03",
  //                              "APP-XX03-14066",
  //                              null,
  //                              OAException.ERROR,
  //                              null);
  //    }
  //    else
  //    {
  //      // �L����(��)�݂̂��w�肳��Ă��鎞
  //      if (invoiceDate.compareTo(recStartDate) < 0)
  //      {
  //        // ���������t < �L����(��)�̎�
  //        throw new OAException("XX03",
  //                              "APP-XX03-14066",
  //                              null,
  //                              OAException.ERROR,
  //                              null);
  //      }
  //    }
  //  }

  //  // �ڋq�ɕR�t���L�����擾
  //  custStartDate = row.getCustStartDate();
  //  custEndDate = row.getCustEndDate();

  //  if(custEndDate == null)
  //  {
  //    custEndDate = invoiceDate;
  //  }

  //  // �x�����@�ɕR�t���L�����`�F�b�N
  //  if (custStartDate != null)
  //  {
  //    // �x�����@�̗L����(��)�����͂���Ă��鎞)�̂݃`�F�b�N
  //    if (custEndDate != null)
  //    {
  //      // �L����(��)�A�L����(��)�������w�肳��Ă��鎞
  //      if ((invoiceDate.compareTo(custStartDate) < 0)
  //          || (invoiceDate.compareTo(custEndDate) > 0))
  //        // ���������t < �L����(��) or ���������t > �L����(��)�̎�
  //        throw new OAException("XX03",
  //                              "APP-XX03-14066",
  //                              null,
  //                              OAException.ERROR,
  //                              null);
  //    }
  //    else
  //    {
  //      // �L����(��)�݂̂��w�肳��Ă��鎞
  //      if (invoiceDate.compareTo(custStartDate) < 0)
  //      {
  //        // ���������t < �L����(��)�̎�
  //        throw new OAException("XX03",
  //                              "APP-XX03-14066",
  //                              null,
  //                              OAException.ERROR,
  //                              null);
  //      }
  //    }
  //  }
    
  //} // checkPaymentDate()
  //ver11.5.10.1.6 Del End

// ver 1.3 Add Start �L�����`�F�b�N�ǉ� ----------------------------------
//  /**
//   * �O����L�����`�F�b�N����
//   * @param startDateCommitment �L����(��)
//   * @param endDateCommitment �L����(��)
//   * @param invoiceDate ���������t
//   * @return �Ȃ�
//   */
//  public void checkCommitmentDate(Date startDateCommitment, Date endDateCommitment,
//    Date invoiceDate)
//  {
//    if (startDateCommitment != null)
//    {
//      // �O����̎�(�L����(��)�����͂���Ă��鎞)�̂݃`�F�b�N
//      if (endDateCommitment != null)
//      {
//        // �L����(��)�A�L����(��)�������w�肳��Ă��鎞
//        if ((invoiceDate.compareTo(startDateCommitment) < 0)
//            || (invoiceDate.compareTo(endDateCommitment) > 0))
//          // ���������t < �L����(��) or ���������t > �L����(��)�̎�
//          throw new OAException("XX03",
//                                "APP-XX03-14065",
//                                null,
//                                OAException.ERROR,
//                                null);
//      }
//      else
//      {
//        // �L����(��)�݂̂��w�肳��Ă��鎞
//        if (invoiceDate.compareTo(startDateCommitment) < 0)
//        {
//          // ���������t < �L����(��)�̎�
//          throw new OAException("XX03",
//                                "APP-XX03-14065",
//                                null,
//                                OAException.ERROR,
//                                null);
//        }
//      }
//    }
//  } // checkCommitmentDate()
//
//  /**
//   * �x�����@�L�����`�F�b�N����
//   * @param startDatePayment �L����(��)
//   * @param endDatePayment �L����(��)
//   * @param invoiceDate ���������t
//   * @return �Ȃ�
//   */
//  public void checkPaymentDate(Date startDatePayment, Date endDatePayment,
//    Date invoiceDate)
//  {
//    if (startDatePayment != null)
//    {
//      // �x�����@�̗L����(��)�����͂���Ă��鎞)�̂݃`�F�b�N
//      if (endDatePayment != null)
//      {
//        // �L����(��)�A�L����(��)�������w�肳��Ă��鎞
//        if ((invoiceDate.compareTo(startDatePayment) < 0)
//            || (invoiceDate.compareTo(endDatePayment) > 0))
//          // ���������t < �L����(��) or ���������t > �L����(��)�̎�
//          throw new OAException("XX03",
//                                "APP-XX03-14066",
//                                null,
//                                OAException.ERROR,
//                                null);
//      }
//      else
//      {
//        // �L����(��)�݂̂��w�肳��Ă��鎞
//        if (invoiceDate.compareTo(startDatePayment) < 0)
//        {
//          // ���������t < �L����(��)�̎�
//          throw new OAException("XX03",
//                                "APP-XX03-14066",
//                                null,
//                                OAException.ERROR,
//                                null);
//        }
//      }
//    }
//  } // checkPaymentDate()
// ver 1.3 Add End ----------------------------------------------------------
// Ver1.4 change end --------------------------------------------------------


  /**
   * ��������
   * @param moduleName ���W���[����
   * @return procedureName �v���V�[�W����
   */
  public void startProcedure(String moduleName, String procedureName)
  {
    OADBTransaction txn = (OADBTransaction)getTransaction();
    if (txn.isLoggingEnabled())
    {
      txn.startTimedProcedure(moduleName, procedureName);    
    }
    // debug
    //    System.out.println("start " + moduleName + "." + procedureName);
  } // startProcedure() 

  /**
   * �I������
   * @param moduleName ���W���[����
   * @return procedureName �v���V�[�W����
   */
  public void endProcedure(String moduleName, String procedureName)
  {
    OADBTransaction txn = (OADBTransaction)getTransaction();
    if (txn.isLoggingEnabled())
    {
      txn.endTimedProcedure(moduleName, procedureName);
    }
    // debug
    //    System.out.println("end   " + moduleName + "." + procedureName);    
  } // endProcedure() 




  /**
   * 
   * Container's getter for Xx03TaxCodesLovVO1
   */
  public Xx03TaxCodesLovVOImpl getXx03TaxCodesLovVO1()
  {
    return (Xx03TaxCodesLovVOImpl)findViewObject("Xx03TaxCodesLovVO1");
  }

  /**
   * 
   * Container's getter for Xx03PrecisionVO1
   */
  public Xx03PrecisionVOImpl getXx03PrecisionVO1()
  {
    return (Xx03PrecisionVOImpl)findViewObject("Xx03PrecisionVO1");
  }

  /**
   * 
   * Container's getter for Xx03ReceivableSlipsVO1
   */
  public Xx03ReceivableSlipsVOImpl getXx03ReceivableSlipsVO1()
  {
    return (Xx03ReceivableSlipsVOImpl)findViewObject("Xx03ReceivableSlipsVO1");
  }


  /**
   * 
   * Container's getter for Xx03ArInvoiceInputSlipPVO1
   */
  public Xx03ArInvoiceInputSlipPVOImpl getXx03ArInvoiceInputSlipPVO1()
  {
    return (Xx03ArInvoiceInputSlipPVOImpl)findViewObject("Xx03ArInvoiceInputSlipPVO1");
  }



  /**
   * 
   * Container's getter for Xx03PrePayButtonVO1
   */
  public Xx03PrePayButtonVOImpl getXx03PrePayButtonVO1()
  {
    return (Xx03PrePayButtonVOImpl)findViewObject("Xx03PrePayButtonVO1");
  }

  /**
   * 
   * Container's getter for Xx03SlipNumbersVO1
   */
  public Xx03SlipNumbersVOImpl getXx03SlipNumbersVO1()
  {
    return (Xx03SlipNumbersVOImpl)findViewObject("Xx03SlipNumbersVO1");
  }

  /**
   * 
   * Container's getter for Xx03GetAutoAccountInfoMemoVO1
   */
  public Xx03GetAutoAccountInfoMemoVOImpl getXx03GetAutoAccountInfoMemoVO1()
  {
    return (Xx03GetAutoAccountInfoMemoVOImpl)findViewObject("Xx03GetAutoAccountInfoMemoVO1");
  }

  /**
   * 
   * Container's getter for Xx03GetAutoAccountInfoCustomerVO1
   */
  public Xx03GetAutoAccountInfoCustomerVOImpl getXx03GetAutoAccountInfoCustomerVO1()
  {
    return (Xx03GetAutoAccountInfoCustomerVOImpl)findViewObject("Xx03GetAutoAccountInfoCustomerVO1");
  }

  /**
   * 
   * Container's getter for Xx03GetTaxOverrideVO1
   */
  public Xx03GetTaxOverrideVOImpl getXx03GetTaxOverrideVO1()
  {
    return (Xx03GetTaxOverrideVOImpl)findViewObject("Xx03GetTaxOverrideVO1");
  }

  /**
   * 
   * Container's getter for Xx03CustTaxOptionVO1
   */
  public Xx03CustTaxOptionVOImpl getXx03CustTaxOptionVO1()
  {
    return (Xx03CustTaxOptionVOImpl)findViewObject("Xx03CustTaxOptionVO1");
  }

  /**
   * 
   * Container's getter for Xx03SystemTaxOptionVO1
   */
  public Xx03SystemTaxOptionVOImpl getXx03SystemTaxOptionVO1()
  {
    return (Xx03SystemTaxOptionVOImpl)findViewObject("Xx03SystemTaxOptionVO1");
  }


  /**
   * 
   * Container's getter for Xx03CheckCommitmentNumberVO1
   */
  public Xx03CheckCommitmentNumberVOImpl getXx03CheckCommitmentNumberVO1()
  {
    return (Xx03CheckCommitmentNumberVOImpl)findViewObject("Xx03CheckCommitmentNumberVO1");
  }

  /**
   * 
   * Container's getter for Xx03ReceivableSlipsLineVO1
   */
  public Xx03ReceivableSlipsLineVOImpl getXx03ReceivableSlipsLineVO1()
  {
    return (Xx03ReceivableSlipsLineVOImpl)findViewObject("Xx03ReceivableSlipsLineVO1");
  }

  /**
   * 
   * Container's getter for Xx03ReceivableSlipsToLinesVL1
   */
  public ViewLinkImpl getXx03ReceivableSlipsToLinesVL1()
  {
    return (ViewLinkImpl)findViewLink("Xx03ReceivableSlipsToLinesVL1");
  }

  /**
   * 
   * Container's getter for Xx03GetCreditTransTypeInfoVO1
   */
  public Xx03GetCreditTransTypeInfoVOImpl getXx03GetCreditTransTypeInfoVO1()
  {
    return (Xx03GetCreditTransTypeInfoVOImpl)findViewObject("Xx03GetCreditTransTypeInfoVO1");
  }

  /**
   * 
   * Container's getter for Xx03GetBaseCurrencyVO1
   */
  public Xx03GetBaseCurrencyVOImpl getXx03GetBaseCurrencyVO1()
  {
    return (Xx03GetBaseCurrencyVOImpl)findViewObject("Xx03GetBaseCurrencyVO1");
  }

  /**
   * 
   * Container's getter for Xx03GetAffPromptVO1
   */
  public Xx03GetAffPromptVOImpl getXx03GetAffPromptVO1()
  {
    return (Xx03GetAffPromptVOImpl)findViewObject("Xx03GetAffPromptVO1");
  }

  /**
   * 
   * Container's getter for Xx03GetDffPromptVO1
   */
  public Xx03GetDffPromptVOImpl getXx03GetDffPromptVO1()
  {
    return (Xx03GetDffPromptVOImpl)findViewObject("Xx03GetDffPromptVO1");
  }

  /**
   * 
   * Container's getter for Xx03TaxClassLovVO1
   */
  public Xx03TaxClassLovVOImpl getXx03TaxClassLovVO1()
  {
    return (Xx03TaxClassLovVOImpl)findViewObject("Xx03TaxClassLovVO1");
  }

  // ver1.3 add start ---------------------------------------------------------
  /**
   * 
   * Container's getter for Xx03SelectedPrecisionVO1
   */
  public Xx03SelectedPrecisionVOImpl getXx03SelectedPrecisionVO1()
  {
    return (Xx03SelectedPrecisionVOImpl)findViewObject("Xx03SelectedPrecisionVO1");
  }
  // ver1.3 add end -----------------------------------------------------------

  // ver1.4 add start ---------------------------------------------------------
  /**
   * 
   * Container's getter for Xx03CommitmentDateVO1
   */
  public Xx03CommitmentDateVOImpl getXx03CommitmentDateVO1()
  {
    return (Xx03CommitmentDateVOImpl)findViewObject("Xx03CommitmentDateVO1");
  }

  // ver1.4 add end -----------------------------------------------------------

  // Ver11.5.10.1.4 2005/07/25 Add Start
  /**
   * 
   * �؏�
   * 
   * @param   calNum    ���l
   * @param   precision ���x
   */
//ver 11.5.10.2.10D Chg Start
//  private Number roundUp(Number calNum,
//                         double precision)
//  {
//    calNum = calNum.multiply(precision);
//    calNum = (Number)calNum.ceil();
//    calNum = calNum.divide(precision);
//
//    return calNum;
//  } // roundUp
  private Number roundUp(Number calNum,
                         Number precision)
  {
    Number numWk = null;
    numWk = new Number(calNum.abs());
    numWk = numWk.multiply(new Number(10).pow(precision));
    numWk = new Number(numWk.ceil());
    numWk = numWk.multiply(new Number(1).mod(10).pow(precision));
    numWk = numWk.multiply(new Number(calNum.sign()));
    return numWk;
  } // roundUp
//ver 11.5.10.2.10D Chg End

  /**
   * 
   * �؎�
   * 
   * @param   calNum    ���l
   * @param   precision ���x
   */
//ver 11.5.10.2.10D Chg Start
//  private Number roundDown(Number calNum,
//                           double precision)
//  {
//    calNum = calNum.multiply(precision);
//    calNum = (Number)calNum.floor();
//    calNum = calNum.divide(precision);
//
//    return calNum;
//  } // roundDown  
  private Number roundDown(Number calNum,
                           Number precision)
  {
    Number numWk = null;
    numWk = new Number(calNum.truncate(precision.intValue()));
    return numWk;
  } // roundDown  
//ver 11.5.10.2.10D Chg End

  /**
   * 
   * �l�̌ܓ�
   * 
   * @param   calNum    ���l
   * @param   precision ���x
   */
//ver 11.5.10.2.10D Chg Start
//  private Number round(Number calNum,
//                       int precision)
//  {
//    calNum = (Number)calNum.round(precision);
//    return calNum;
//  } // round
  private Number round(Number calNum,
                       Number precision)
  {
    Number numWk = null;
    numWk = new Number(calNum.round(precision.intValue()));
    return numWk;
  } // round
//ver 11.5.10.2.10D Chg End


  // Ver11.5.10.1.4 2005/07/25 add end

  /**
   * 
   * Container's getter for Xx03ConfirmDispSlipsVO1
   */
  public Xx03ConfirmDispSlipsVOImpl getXx03ConfirmDispSlipsVO1()
  {
    return (Xx03ConfirmDispSlipsVOImpl)findViewObject("Xx03ConfirmDispSlipsVO1");
  }

  /**
   * 
   * Container's getter for Xx03ConfirmDispSlipsLineVO1
   */
  public Xx03ConfirmDispSlipsLineVOImpl getXx03ConfirmDispSlipsLineVO1()
  {
    return (Xx03ConfirmDispSlipsLineVOImpl)findViewObject("Xx03ConfirmDispSlipsLineVO1");
  }

  /**
   * 
   * Container's getter for Xx03ConfirmUpdSlipsVO1
   */
  public Xx03ConfirmUpdSlipsVOImpl getXx03ConfirmUpdSlipsVO1()
  {
    return (Xx03ConfirmUpdSlipsVOImpl)findViewObject("Xx03ConfirmUpdSlipsVO1");
  }

  /**
   * 
   * Container's getter for Xx03ConfirmDispSlipsToLinesVL1
   */
  public ViewLinkImpl getXx03ConfirmDispSlipsToLinesVL1()
  {
    return (ViewLinkImpl)findViewLink("Xx03ConfirmDispSlipsToLinesVL1");
  }

  //ver11.5.10.1.6 Add Start
  /**
   * �����`�[�̌����i�m�F��ʗp�j
   * @param receivableId �����ԍ�
   * @param executeQuery 
   * @return �Ȃ�
   */
  public void initConfirmReceivableSlips(Number receivableId)
  {
    // ����������
    String methodName = "initConfirmReceivableSlips";
    startProcedure(getClass().getName(), methodName);

    // �\���p�r���[�E�I�u�W�F�N�g�̎擾
    Xx03ConfirmDispSlipsVOImpl dispVo = getXx03ConfirmDispSlipsVO1();
    dispVo.initQuery(receivableId);

    // �X�V�p�r���[�E�I�u�W�F�N�g�̎擾
    Xx03ConfirmUpdSlipsVOImpl  updVo  = getXx03ConfirmUpdSlipsVO1();
    updVo.initQuery(receivableId);

    // �I������
    endProcedure(getClass().getName(), methodName);
  } // end initConfirmReceivableSlips()
  //ver11.5.10.1.6 Add End

  //ver11.5.10.1.6 Add Start
  /**
   * �m�F��ʂł̓`�[�̕ۑ�
   * @param �Ȃ�
   * @return �Ȃ�
   */
  public void confirmSave()
  {
    // ����������
    String methodName = "confirmSave";
    startProcedure(getClass().getName(), methodName);

    // �r���[�E�I�u�W�F�N�g�̎擾
    int fetchedHeaderRowCount;
    RowSetIterator selectHeaderIter = null;
    OAViewObject headerVo = getXx03ConfirmUpdSlipsVO1();

    try
    {
      Xx03ConfirmUpdSlipsVORowImpl headerRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedHeaderRowCount = headerVo.getFetchedRowCount();
      fetchedHeaderRowCount = headerVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectHeaderIter = headerVo.createRowSetIterator("selectHeaderIter");

      if (fetchedHeaderRowCount > 0)
      {
        selectHeaderIter.setRangeStart(0);
        selectHeaderIter.setRangeSize(fetchedHeaderRowCount);

        headerRow = (Xx03ConfirmUpdSlipsVORowImpl)selectHeaderIter.first();
      } // fetchedHeaderRocCount
      else
      {
        // �G���[�E���b�Z�[�W
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ConfirmUpdSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);
      } // fetchedHeaderRowCount
    
      try
      {
        // COMMIT
        getTransaction().commit();
      }
      catch(OAException ex)
      {
        throw OAException.wrapperException(ex);
      }

      // �I������
      endProcedure(getClass().getName(), methodName);
    }
    finally
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();
      }
    }
  } // confirmSave()
  //ver11.5.10.1.6 Add End

  //ver11.5.10.1.6 Add Start
  /**
   * ���F�K�w�N���X���擾����
   * @param �Ȃ�
   * @return �Ȃ�
   * @return String ���F�K�w�N���X�l
   */
  public String confirmRecognitionClass()
  {
    // ����������
    String methodName = "confirmRecognitionClass";
    startProcedure(getClass().getName(), methodName);
    
    String retValue = null;
    Number recognitionClass;
    
    // �r���[�E�I�u�W�F�N�g�̎擾
    Xx03ConfirmDispSlipsVOImpl    vo  = getXx03ConfirmDispSlipsVO1();
    if(vo.first() != null)
    {
      vo.first();
      Xx03ConfirmDispSlipsVORowImpl row = (Xx03ConfirmDispSlipsVORowImpl)vo.getCurrentRow();
      recognitionClass = row.getRecognitionClass();
      if(recognitionClass != null)
      {
        retValue = recognitionClass.toString();
      }
    }
    // �I������
    endProcedure(getClass().getName(), methodName);
    return retValue;
  }
  //ver11.5.10.1.6 Add End

  //ver11.5.10.1.6 Add Start
  /**
   * �O����{�^���\���敪�擾
   * @param �Ȃ�
   * @return �O����\���敪
   */
  public String confirmPrePay()
  {
    // ����������
    String methodName = "confirmPrePay";
    startProcedure(getClass().getName(), methodName);
    
    RowSetIterator selectDispIter = null;     
    int fetchedDispRowCount;
    String retStr = "N";  // �O����\���敪

    try
    {
      Xx03ConfirmDispSlipsVOImpl    dispVo    = getXx03ConfirmDispSlipsVO1();
      Xx03ConfirmDispSlipsVORowImpl dispRow   = null;

      Xx03PrePayButtonVOImpl        prepayVo  = getXx03PrePayButtonVO1();
      Xx03PrePayButtonVORowImpl     prepayRow = null;

      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedDispRowCount = dispVo.getFetchedRowCount();
      fetchedDispRowCount = dispVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectDispIter      = dispVo.createRowSetIterator("selectDispIter");

      if (fetchedDispRowCount > 0)
      {
        selectDispIter.setRangeStart(0);
        selectDispIter.setRangeSize(fetchedDispRowCount);

        dispRow = (Xx03ConfirmDispSlipsVORowImpl)selectDispIter.first();

        if (dispRow != null)
        {
          // �`�[��ʎ擾
          String slipType = dispRow.getSlipType();

          // �O����\���敪�擾
          prepayVo.initQuery(slipType);
          prepayRow = (Xx03PrePayButtonVORowImpl)prepayVo.first();
          
          if (prepayRow != null)
          {
            retStr = prepayRow.getAttribute12();
          }
        } // headerRow
      } // fetchedHeaderRocCount
      else
      {
        // �G���[�E���b�Z�[�W
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ConfirmDispSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);
      } // fetchedHeaderRowCount 
    
      // �I������
      endProcedure(getClass().getName(), methodName);
    }
    finally
    {
      if(selectDispIter != null)
      {
        selectDispIter.closeRowSetIterator();
      }
    }
    return retStr;
  } // confirmPrePay()
  //ver11.5.10.1.6 Add End

  //ver11.5.10.1.6 Add Start
  /**
   * �`�[��ʂ��L������Ԃ��B
   * @return String 'Y':�L�� 'N':����
   */
  public String retEnableSlipType()
  {

    Xx03ConfirmDispSlipsVOImpl hVo = getXx03ConfirmDispSlipsVO1();
    hVo.first();

    Xx03ConfirmDispSlipsVORowImpl hRow =
      (Xx03ConfirmDispSlipsVORowImpl)hVo.getCurrentRow();

    //Ver11.5.10.1.6C 2005/12/08 Change Start
    //Xx03SlipTypesLovVOImpl vo = getXx03SlipTypesLovVO1();
    Xx03EnableSlipTypeVOImpl vo = getXx03EnableSlipTypeVO1();
    //Ver11.5.10.1.6C 2005/12/08 Change End
    vo.initQuery(hRow.getSlipType());

    String retStr = "N";
    if (vo.first() != null)
    {
      retStr = "Y";
    }

    return retStr;
  }
  //ver11.5.10.1.6 Add End

  //Ver11.5.10.1.6G 2005/12/27 Add Start
  /**
   * �`�[��ʂ��L������Ԃ��B
   * @return String 'Y':�L�� 'N':���� 'A':�A�v������
   */
  public String retEnableSlipType2()
  {
    String retStr = "N";

    Xx03SlipTypesLovVOImpl    slipVo  = getXx03SlipTypesLovVO1();
    if (slipVo.first() == null)
    {
      retStr = "N";
    }
    else
    {
      Xx03SlipTypesLovVORowImpl slipRow = (Xx03SlipTypesLovVORowImpl)slipVo.getCurrentRow();
      String att14 = slipRow.getAttribute14();

      if (att14 == null || "".equals(att14))
      {
        retStr = "A";
      }
      else
      {
        retStr = "Y";
      }
    }

    return retStr;
  }
  //Ver11.5.10.1.6G 2005/12/27 Add End

  //ver11.5.10.2.3 Add Start
  /**
   * �`�[��ʂ����j���[�ŗL������Ԃ��B
   * @return String 'Y1':�L��(������`�[) 'Y2':�L��(������`�[)
   *                'N1':����(������`�[) 'N2':����(������`�[)
   */
  public String retEnableSlipType3()
  {

    Xx03ConfirmDispSlipsVOImpl hVo = getXx03ConfirmDispSlipsVO1();
    hVo.first();
    Xx03ConfirmDispSlipsVORowImpl hRow =
      (Xx03ConfirmDispSlipsVORowImpl)hVo.getCurrentRow();

    Xx03ChkUsrDepartmentVOImpl dVo = getXx03ChkUsrDepartmentVO1();
    dVo.initQuery(hRow.getEntryDepartment());
    dVo.first();
    Xx03ChkUsrDepartmentVORowImpl dRow =
      (Xx03ChkUsrDepartmentVORowImpl)dVo.getCurrentRow();
    Number dCnt = dRow.getCnt();
    
    Xx03GetArMenuSlipTypeVOImpl mVo = getXx03GetArMenuSlipTypeVO1();
    mVo.initQuery(hRow.getSlipType());
    mVo.first();
    Xx03GetArMenuSlipTypeVORowImpl mRow =
      (Xx03GetArMenuSlipTypeVORowImpl)mVo.getCurrentRow();
    Number mCnt = mRow.getCnt();

    String retStr = "";
    if (mCnt.intValue() != 0)
    {
      if(dCnt.intValue() != 0)
      {
        retStr = "Y1";
      }
      else
      {
        retStr = "Y2";
      }
    }
    else
    {
      if(dCnt.intValue() != 0)
      {
        retStr = "N1";
      }
      else
      {
        retStr = "N2";
      }
    }

    return retStr;
  }
  //ver11.5.10.2.3 Add End

  //ver11.5.10.3 Add Start
  /**
   * �ڋqID�`�F�b�N
   * @param  customerId �ڋqID
   * @return exception  �G���[���X�g
   */
  public Vector checkCustomerId( Number customerId)           // �ڋq�h�c
  {
    // �G���[���b�Z�[�W�̏���
    OAException  msg         = null;                         // �G���[���b�Z�[�W
    MessageToken slipNumTok  = null;                         // �`�[�ԍ��g�[�N��
    Vector exception         = new Vector();
    byte         messageType = OAException.ERROR;            // �G���[�^�C�v

    // �ڋq�`�F�b�N�i�ڋq�h�c���ݎ����s�j
    if ( (customerId != null) && (!customerId.equals("")) )
    {
      int customerInfo = getCustomerId(customerId);
      if (customerInfo == 0)
      {
        msg = new OAException( "XXCFR" ,"APP-XXCFR1-10001" );
        exception.addElement(msg);
      }
    }
    return exception;
  }
  //ver11.5.10.3 Add End

  //ver11.5.10.1.6 Add Start
  /**
   * �w�b�_�̃}�X�^�`�F�b�N
   * @param  headerRow  �w�b�_�s
   * @param  methodName �ďo�����\�b�h��
   * @return exception  �G���[���X�g
   */
  //ver 11.5.10.1.6I Chg Start
  //public Vector validateHeader( Vector exception
  //                             ,String methodName
  //                             ,String slipNum              // �`�[�ԍ�
  //                             ,String slipType             // �`�[��ʃR�[�h
  //                             ,Number transTypeId          // ����h�c
  //                             ,Number customerId           // �ڋq�h�c
  //                             ,Number custOfficeId         // �ڋq���Ə��h�c
  //                             ,Number receiptMethodId      // �x�����@�h�c
  //                             ,Number termsId              // �x�������h�c
  //                             ,String currencyCode         // �ʉ݃R�[�h
  //                             ,Date   invoiceDate          // ���������t
  //                             ,String origInvoiceNum       // �C�����`�[�ԍ�
  //                             )
  public Vector validateHeader( Vector exception
                               ,String methodName
                               ,String slipNum              // �`�[�ԍ�
                               ,String slipType             // �`�[��ʃR�[�h
                               ,Number transTypeId          // ����h�c
                               ,Number customerId           // �ڋq�h�c
                               ,Number custOfficeId         // �ڋq���Ə��h�c
                               ,Number receiptMethodId      // �x�����@�h�c
                               ,Number termsId              // �x�������h�c
                               ,String currencyCode         // �ʉ݃R�[�h
                               ,Date   invoiceDate          // ���������t
                               ,String origInvoiceNum       // �C�����`�[�ԍ�
                               ,String wfStatus             // ���[�N�t���[�X�e�[�^�X
                               ,Number approverId           // ���F��ID
                               ,String slipTypeApp          // �`�[��ʃA�v��
                               )
  //ver 11.5.10.1.6I Chg End
  {
    // �G���[���b�Z�[�W�̏���
    OAException  msg         = null;                         // �G���[���b�Z�[�W
    MessageToken slipNumTok  = null;                         // �`�[�ԍ��g�[�N��
    byte         messageType = OAException.ERROR;            // �G���[�^�C�v
    
    // �g�[�N���̏���
    if (methodName.equals("checkAllValidation"))
    {
      // �ꊇ���F����̌ďo�̏ꍇ�A�G���[���b�Z�[�W�ɓ`�[�ԍ��ǉ�
      slipNumTok = new MessageToken("SLIP_NUM", slipNum + ":");
    }
    else
    {
      // �m�F��ʂ���̌ďo�̏ꍇ�A�`�[�ԍ��͕\�����Ȃ�
      slipNumTok = new MessageToken("SLIP_NUM", "");
    }
    
    
    //ver 11.5.10.1.6I Add Start
    // ���F�҃`�F�b�N�i���F�҂h�c,�`�[��ʃA�v�� ���ݎ����s�j
    if (    (approverId  != null) && (!approverId.equals("") )
         && (slipTypeApp != null) && (!slipTypeApp.equals(""))
         && (    (Xx03CommonUtil.STATUS_SAVE.equals(wfStatus)       )
              || (Xx03CommonUtil.STATUS_BEFORE_DEPT.equals(wfStatus))) )
    {
      ArrayList approverInfo = getApproverName(approverId, slipTypeApp);
      if (approverInfo.isEmpty())
      {
        // ���F�ҕs���G���[
        msg = new OAException( "XX03" ,"APP-XX03-14154"
                              ,new MessageToken[]{slipNumTok} ,messageType ,null);
        exception.addElement(msg);
      }
    }
    //ver 11.5.10.1.6I Add End
    
    // ����^�C�v�`�F�b�N�i����^�C�v,���������t,�`�[��ʃR�[�h ���ݎ����s�j
    // ���A����`�[�Ŗ����ꍇ�i�������̏ꍇ�͎���^�C�v=����ŌŒ�̂��߃`�F�b�N�s�v�j
    if (    (transTypeId != null) && (!transTypeId.equals(""))
         && (invoiceDate != null) && (!invoiceDate.equals(""))
         && (slipType    != null) && (!slipType.equals("")   )
         && (origInvoiceNum == null)                           )
    {
      ArrayList transTypeInfo = getTransTypeName(transTypeId ,invoiceDate ,slipType);
      if (transTypeInfo.isEmpty())
      { 
        msg = new OAException( "XX03" ,"APP-XX03-13060"
                              ,new MessageToken[]{slipNumTok} ,messageType ,null);
        exception.addElement(msg);
      }
    }
    
    // �ڋq�`�F�b�N�i�ڋq�h�c���ݎ����s�j
    if ( (customerId != null) && (!customerId.equals("")) )
    {
      ArrayList customerInfo = getCustomerName(customerId);
      if (customerInfo.isEmpty())
      {
        msg = new OAException( "XX03" ,"APP-XX03-13061"
                              ,new MessageToken[]{slipNumTok} ,messageType ,null);
        exception.addElement(msg);
      }
    }
  
    // �ڋq���Ə��`�F�b�N�i�ڋq�h�c,�ڋq���Ə��h�c���ݎ����s�j
    if (    (customerId   != null) && (!customerId.equals("")  )
         && (custOfficeId != null) && (!custOfficeId.equals("")) )
    {
      ArrayList custOfficeInfo = getCustOfficeName(custOfficeId, customerId);
      if (custOfficeInfo.isEmpty())
      {
        msg = new OAException( "XX03" ,"APP-XX03-13062"
                              ,new MessageToken[]{slipNumTok} ,messageType ,null);
       exception.addElement(msg);
      }
    }

    //ver 11.5.10.2.6 Chg Start
    //// �ʉ݃R�[�h�`�F�b�N�i�ʉ݃R�[�h,���������t���ݎ����s�j
    //if (    (currencyCode != null) && (!currencyCode.equals(""))
    //     && (invoiceDate  != null) && (!invoiceDate.equals("") ) )
    // �ʉ݃`�F�b�N�i�ʉ݃R�[�h ���ݎ����s�j
    if ((currencyCode != null) && (!currencyCode.equals("")))
    //ver 11.5.10.2.6 Chg End
    {
      //ver 11.5.10.2.6 Chg Start
      //ArrayList currencyInfo = getCurrencyName(currencyCode, invoiceDate);
      //ver 11.5.10.2.10 Chg Start
      //ArrayList currencyInfo = getCurrencyName(currencyCode);
      ArrayList currencyInfo = getCurrencyName(currencyCode, invoiceDate);
      //ver 11.5.10.2.10 Chg End
      //ver 11.5.10.2.6 Chg End
      if (currencyInfo.isEmpty())
      {
        msg = new OAException( "XX03" ,"APP-XX03-14150"
                              ,new MessageToken[]{slipNumTok} ,messageType ,null);
        exception.addElement(msg);
      }
    }

    // �x�����@�`�F�b�N�i�x�����@�h�c,�ڋq���Ə��h�c,�ʉ݃R�[�h���ݎ����s�j
    if (    (custOfficeId    != null) && (!custOfficeId.equals("")   )
         && (receiptMethodId != null) && (!receiptMethodId.equals(""))
         && (currencyCode    != null) && (!currencyCode.equals("")   )
         && (invoiceDate     != null) && (!invoiceDate.equals("")    ) )
    {
      ArrayList receiptMethodInfo = getReceiptMethodName(receiptMethodId, custOfficeId, currencyCode, invoiceDate);
      if (receiptMethodInfo.isEmpty())
      {
        msg = new OAException( "XX03" ,"APP-XX03-13063"
                              ,new MessageToken[]{slipNumTok} ,messageType ,null);
        exception.addElement(msg);
      }
    }

    // �x�������`�F�b�N�i�x�������h�c,���������t���ݎ����s�j
    if (    (termsId     != null) && (!termsId.equals("")    )
         && (invoiceDate != null) && (!invoiceDate.equals("")) )
    {
      ArrayList termsInfo = getTermsName(termsId, invoiceDate);
      if (termsInfo.isEmpty())
      {
        msg = new OAException( "XX03" ,"APP-XX03-13064"
                              ,new MessageToken[]{slipNumTok} ,messageType ,null);
        exception.addElement(msg);
      }
    }

    return exception;
  }

  /**
   * ����^�C�v���̎擾
   * @param  transTypeId ����^�C�v�h�c
   * @param  slipType    �`�[���
   * @return returnInfo  ����^�C�v����
   */
  public ArrayList getTransTypeName(Number transTypeId ,Date invoiceDate ,String slipType)
  {
    String    transTypeName = null;
    ArrayList returnInfo    = new ArrayList();

    Xx03GetTransTypeNameVOImpl    vo  = getXx03GetTransTypeNameVO1();
    Xx03GetTransTypeNameVORowImpl row = null;

    vo.initQuery(transTypeId ,invoiceDate ,slipType);
    RowSetIterator selectIter = vo.createRowSetIterator("selectIter");

    int rowCount = vo.getRowCount();
    if (rowCount == 1)
    {
      selectIter.setRangeStart(0);
      selectIter.setRangeSize(rowCount);

      row = (Xx03GetTransTypeNameVORowImpl)selectIter.getRowAtRangeIndex(0);
      
      if (row != null)
      {
        transTypeName = row.getName();
      }
      returnInfo.add(transTypeName);
    }
    selectIter.closeRowSetIterator();
    return returnInfo; 
  } // getTransTypeName

  //ver11.5.10.3 Add Start
  /**
   * �ڋqID�擾�i�Z�L�����e�B�`�F�b�N�j
   * @param  customerId  �ڋqID
   * @return returnInfo  �ڋqID
   */
   public int getCustomerId(Number customerId)
   {
     int returnInfo    = 0;

     Xx03ChkArCustomerVOImpl    vo  = Xx03ChkArCustomerVO1();

     vo.initQuery(customerId);

     Xx03ChkArCustomerVORowImpl row = (Xx03ChkArCustomerVORowImpl)vo.first();
     Number customer_cnt = row.getCustomerCnt();
     if (customer_cnt.intValue() != 0)
     {
       returnInfo = 1;
     }
     return returnInfo; 
   } // getCustomerId
  //ver11.5.10.3 Add End

  /**
   * �ڋq���̎擾
   * @param  customerId  �ڋq�h�c
   * @param  transTypeId ����^�C�v�h�c
   * @param  slipType    �`�[��ʃR�[�h
   * @return returnInfo  �ڋq����
   */
  public ArrayList getCustomerName(Number customerId)
  {
    String    customerName  = null;
    ArrayList returnInfo    = new ArrayList();

    Xx03GetArCustomerNameVOImpl    vo  = getXx03GetArCustomerNameVO1();
    Xx03GetArCustomerNameVORowImpl row = null;

    vo.initQuery(customerId);
    RowSetIterator selectIter = vo.createRowSetIterator("selectIter");

    int rowCount = vo.getRowCount();
    if (rowCount == 1)
    {
      selectIter.setRangeStart(0);
      selectIter.setRangeSize(rowCount);

      row = (Xx03GetArCustomerNameVORowImpl)selectIter.getRowAtRangeIndex(0);
      
      if (row != null)
      {
        customerName = row.getName();
      }
      returnInfo.add(customerName);
    }
    selectIter.closeRowSetIterator();
    return returnInfo; 
  } // getCustomerName

  /**
   * �ڋq���Ə����̎擾
   * @param  custOfficeId �ڋq���Ə��h�c
   * @param  customerId   �ڋq�h�c
   * @return returnInfo   �ڋq���Ə�����
   */
  public ArrayList getCustOfficeName(Number custOfficeId, Number customerId)
  {
    String    custOfficeName = null;
    ArrayList returnInfo     = new ArrayList();

    Xx03GetArCustSiteNameVOImpl    vo  = getXx03GetArCustSiteNameVO1();
    Xx03GetArCustSiteNameVORowImpl row = null;

    vo.initQuery(custOfficeId, customerId);
    RowSetIterator selectIter = vo.createRowSetIterator("selectIter");

    int rowCount = vo.getRowCount();
    if (rowCount == 1)
    {
      selectIter.setRangeStart(0);
      selectIter.setRangeSize(rowCount);

      row = (Xx03GetArCustSiteNameVORowImpl)selectIter.getRowAtRangeIndex(0);
      
      if (row != null)
      {
        custOfficeName = row.getName();
      }
      returnInfo.add(custOfficeName);
    }    
    selectIter.closeRowSetIterator();
    return returnInfo; 
  } // getCustOfficeName

  /**
   * �ʉݖ��̎擾
   * @param  invoiceCurrencyCode  �ʉ݃R�[�h
   * @return returnInfo           �ʉݖ���
   */
  // ver 11.5.10.2.6 Chg Start
  //public ArrayList getCurrencyName(String invoiceCurrencyCode, Date invoiceDate)
  //ver 11.5.10.2.10 Chg Start
  //public ArrayList getCurrencyName(String invoiceCurrencyCode)
  public ArrayList getCurrencyName(String invoiceCurrencyCode, Date invoiceDate)
  //ver 11.5.10.2.10 Chg End
  // ver 11.5.10.2.6 Chg End
  {
    String    currencyName = null;
    ArrayList returnInfo   = new ArrayList();

    Xx03GetCurrencyNameVOImpl    vo  = getXx03GetCurrencyNameVO1();
    Xx03GetCurrencyNameVORowImpl row = null;

    // ver 11.5.10.2.6 Chg Start
    //vo.initQuery(invoiceCurrencyCode, invoiceDate);
    //ver 11.5.10.2.10 Chg Start
    //vo.initQuery(invoiceCurrencyCode);
    vo.initQuery(invoiceCurrencyCode, invoiceDate);
    //ver 11.5.10.2.10 Chg End
    // ver 11.5.10.2.6 Chg End
    RowSetIterator selectIter = vo.createRowSetIterator("selectIter");

    int rowCount = vo.getRowCount();
    if (rowCount == 1)
    {
      selectIter.setRangeStart(0);
      selectIter.setRangeSize(rowCount);

      row = (Xx03GetCurrencyNameVORowImpl)selectIter.getRowAtRangeIndex(0);
      
      if (row != null)
      {
        currencyName = row.getName();
      }
      returnInfo.add(currencyName);
    }
    selectIter.closeRowSetIterator();
    return returnInfo; 
  } // getCurrencyName

  /**
   * �x�����@���̎擾
   * @param  receiptMethodId �ڋq���Ə��h�c
   * @param  receiptMethodId �ڋq�h�c
   * @param  currencyCode    �ʉ݃R�[�h
   * @return returnInfo      �x�����@����
   */
  public ArrayList getReceiptMethodName(Number receiptMethodId, Number custOfficeId, String currencyCode, Date invoiceDate)
  {
    String    receiptMethodName = null;
    ArrayList returnInfo        = new ArrayList();

    Xx03GetReceiptMethodNameVOImpl    vo  = getXx03GetReceiptMethodNameVO1();
    Xx03GetReceiptMethodNameVORowImpl row = null;

    vo.initQuery(receiptMethodId, custOfficeId, currencyCode, invoiceDate);
    RowSetIterator selectIter = vo.createRowSetIterator("selectIter");

    int rowCount = vo.getRowCount();
    if (rowCount == 1)
    {
      selectIter.setRangeStart(0);
      selectIter.setRangeSize(rowCount);

      row = (Xx03GetReceiptMethodNameVORowImpl)selectIter.getRowAtRangeIndex(0);
      
      if (row != null)
      {
        receiptMethodName = row.getName();
      }
      returnInfo.add(receiptMethodName);
    }
    selectIter.closeRowSetIterator();
    return returnInfo; 
  } // getReceiptMethodName

  /**
   * �x���������̎擾
   * @param  termsId     �x�������h�c
   * @param  invoiceDate ���������t
   * @return returnInfo  �x����������
   */
  public ArrayList getTermsName(Number termsId, Date invoiceDate)
  {
    String    termsName  = null;
    ArrayList returnInfo = new ArrayList();

    Xx03GetTermsNameVOImpl    vo  = getXx03GetTermsNameVO1();
    Xx03GetTermsNameVORowImpl row = null;

    vo.initQuery(termsId, invoiceDate);
    RowSetIterator selectIter = vo.createRowSetIterator("selectIter");

    int rowCount = vo.getRowCount();
    if (rowCount == 1)
    {
      selectIter.setRangeStart(0);
      selectIter.setRangeSize(rowCount);

      row = (Xx03GetTermsNameVORowImpl)selectIter.getRowAtRangeIndex(0);
      
      if (row != null)
      {
        termsName = row.getName();
      }
      returnInfo.add(termsName);
    }
    selectIter.closeRowSetIterator();
    return returnInfo; 
  } // getTermsName

  //ver 11.5.10.1.6I Add Start
  /**
   * ���F�Җ��̎擾
   * @param  approverId   ���F�҂h�c
   * @param  slipTypeApp  �`�[��ʃA�v��
   * @return returnInfo   ���F�Җ���
   */
  public ArrayList getApproverName(Number approverId, String slipTypeApp)
  {
    String    approverName = null;
    ArrayList returnInfo = new ArrayList();

    Xx03GetApproverNameVOImpl    vo  = getXx03GetApproverNameVO1();
    Xx03GetApproverNameVORowImpl row = null;

    vo.initQuery(approverId, slipTypeApp);
    RowSetIterator selectIter = vo.createRowSetIterator("selectIter");

    int rowCount = vo.getRowCount();
    if (rowCount == 1)
    {
      selectIter.setRangeStart(0);
      selectIter.setRangeSize(rowCount);

      row = (Xx03GetApproverNameVORowImpl)selectIter.getRowAtRangeIndex(0);
      
      if (row != null)
      {
        approverName = row.getName();
      }
      returnInfo.add(approverName);
    }
    selectIter.closeRowSetIterator();
    return returnInfo;
  } // getApproverName
  //ver 11.5.10.1.6I Add End

  /**
   * ���ׂ̃}�X�^�`�F�b�N
   * @param  headerRow  �w�b�_�[�s
   * @param  lineRow    ���׍s
   * @param  exception  �G���[���X�g
   * @param  count      ���׍s��
   * @param  methodName �ďo�����\�b�h��
   * @return exception  �G���[���X�g
   */
  //Ver11.5.10.1.6E 2005/12/26 Change Start
  //public Vector validateLine( Vector exception
  //                           ,int    count
  //                           ,String methodName
  //                           ,String slipNum              // �`�[�ԍ�
  //                           ,String slipType             // �`�[��ʃR�[�h
  //                           ,Date   invoiceDate          // ���������t
  //                           ,Number slipLineType         // �������e�h�c
  //                           ,String slipLineUom          // �P��
  //                           )
  public Vector validateLine( Vector exception
                             ,int    count
                             ,String methodName
                             ,String slipNum              // �`�[�ԍ�
                             //ver 11.5.10.1.6Q Del Start
                             //,String slipType             // �`�[��ʃR�[�h
                             //ver 11.5.10.1.6Q Del End
                             ,Date   invoiceDate          // ���������t
                             //ver 11.5.10.1.6Q Del Start
                             //,Number slipLineType         // �������e�h�c
                             //ver 11.5.10.1.6Q Del End
                             ,String slipLineUom          // �P��
                             ,String slipLineTaxName      // �Ŗ���
                             ,String slipLineTaxCode      // �ŃR�[�h
                             //Ver11.5.10.1.6P Add Start
                             ,Number slipLineTaxId        // ��ID
                             //Ver11.5.10.1.6P Add End
                             //Ver11.5.10.1.6R Add Start
                             ,String includesTaxFlag      // ���Ńt���O
                             //Ver11.5.10.1.6R Add End
                             )
  //Ver11.5.10.1.6E 2005/12/26 Change End
  {
    // �G���[���b�Z�[�W�̏���
    OAException msg = null;               // �G���[���b�Z�[�W
    byte messageType = OAException.ERROR; // �G���[�^�C�v
    MessageToken countTok = null;         // �s�ԍ��g�[�N��
    MessageToken slipNumTok = null;       // �`�[�ԍ��g�[�N��
    String strCount = new Integer(count + 1).toString();
    
    // �g�[�N���̏���
    if (methodName.equals("checkAllValidation"))
    {
      // �ꊇ���F����̌ďo�̏ꍇ�A�G���[���b�Z�[�W�ɓ`�[�ԍ��ǉ�
      slipNumTok = new MessageToken("SLIP_NUM", slipNum + ":");
    }
    else
    {
      // �m�F��ʂ���̌ďo�̏ꍇ�A�`�[�ԍ��͕\�����Ȃ�
      slipNumTok = new MessageToken("SLIP_NUM", "");
    }
    countTok = new MessageToken("TOK_COUNT", strCount);
    
    //ver 11.5.10.1.6Q Del Start
    //// �������e�`�F�b�N�i�������e�h�c,���������t���ݎ����s�j
    //if (    (slipLineType != null) && (!slipLineType.equals(""))
    //     && (invoiceDate  != null) && (!invoiceDate.equals("") )
    //     && (slipType     != null) && (!slipType.equals("")    ))
    //{
    //  ArrayList slipLineTypeInfo = getSlipLineTypeName(slipLineType, invoiceDate, slipType);
    //  if (slipLineTypeInfo.isEmpty())
    //  {
    //    msg = new OAException( "XX03" ,"APP-XX03-13065"
    //                          ,new MessageToken[]{slipNumTok ,countTok} ,messageType ,null);
    //    exception.addElement(msg);
    //  }
    //}
    //ver 11.5.10.1.6Q Del End

    //ver 11.5.10.2.6 Chg Start
    //// �P�ʃ`�F�b�N�i�P�ʑ��ݎ����s�j
    //if (    (slipLineUom != null) && (!slipLineUom.equals(""))
    //     && (invoiceDate != null) && (!invoiceDate.equals("")) )
    // �P�ʃ`�F�b�N�i�P�ʑ��ݎ����s�j
    if ((slipLineUom != null) && (!slipLineUom.equals("")))
    //ver 11.5.10.2.6 Chg End
    {
      //ver 11.5.10.2.6 Chg Start
      //ArrayList uomInfo = getUomID(slipLineUom, invoiceDate);
      ArrayList uomInfo = getUomID(slipLineUom);
      //ver 11.5.10.2.6 Chg End
      if (uomInfo.isEmpty())
      {
        msg = new OAException( "XX03" ,"APP-XX03-13066"
                              ,new MessageToken[]{slipNumTok ,countTok} ,messageType ,null);
        exception.addElement(msg);         
      }
    }
    
    //Ver11.5.10.1.6E 2005/12/26 Change Start
    // �ŋ��R�[�h�`�F�b�N�i���������t���ݎ����s�j
    if (    (invoiceDate     != null) && (!invoiceDate.equals("")    )
         && (slipLineTaxName != null) && (!slipLineTaxName.equals(""))
         && (slipLineTaxCode != null) && (!slipLineTaxCode.equals("")) )
    {
      ArrayList slipLineTaxInfo = getSlipLineTaxName(slipLineTaxName, slipLineTaxCode, invoiceDate);
      if (slipLineTaxInfo.isEmpty())
      {
        msg = new OAException( "XX03" ,"APP-XX03-14151"
                              ,new MessageToken[]{slipNumTok ,countTok} ,messageType ,null);
        exception.addElement(msg);
      }
      //Ver11.5.10.1.6P Add Start
      else
      {
        Number getTaxId = (Number)slipLineTaxInfo.get(1);
        //Ver11.5.10.1.6R Add Start
        String getIncTaxFlag = (String)slipLineTaxInfo.get(2);
        //Ver11.5.10.1.6R Add End
        if (!slipLineTaxId.equals(getTaxId))
        {
          msg = new OAException( "XX03" ,"APP-XX03-14151"
                                ,new MessageToken[]{slipNumTok ,countTok} ,messageType ,null);
          exception.addElement(msg);
        }
        //Ver11.5.10.1.6R Add Start
        else if (!getIncTaxFlag.equals(includesTaxFlag))
        {
          msg = new OAException( "XX03" ,"APP-XX03-13070"
                                ,new MessageToken[]{slipNumTok ,countTok} ,messageType ,null);
          exception.addElement(msg);
        }
        //Ver11.5.10.1.6R Add End
      }
      //Ver11.5.10.1.6P Add End
    }
    //Ver11.5.10.1.6E 2005/12/26 Change End
    
    return exception;
  }

  /**
   * �������e���̎擾
   * @param  slipLinetype �������e�h�c
   * @param  invoiceDate  ���������t
   * @return returnInfo   �������e����   
   */
  public ArrayList getSlipLineTypeName(Number slipLineType, Date invoiceDate, String slipType)
  {
    String    slipLineTypeName = null;
    ArrayList returnInfo       = new ArrayList();

    Xx03GetArLinesNameVOImpl    vo  = getXx03GetArLinesNameVO1();
    Xx03GetArLinesNameVORowImpl row = null;

    vo.initQuery(slipLineType, invoiceDate, slipType);
    RowSetIterator selectIter = vo.createRowSetIterator("selectIter");

    int rowCount = vo.getRowCount();
    if (rowCount == 1)
    {
      selectIter.setRangeStart(0);
      selectIter.setRangeSize(rowCount);

      row = (Xx03GetArLinesNameVORowImpl)selectIter.getRowAtRangeIndex(0);
      
      if (row != null)
      {
        slipLineTypeName = row.getName();
      }
      returnInfo.add(slipLineTypeName);
    }
    selectIter.closeRowSetIterator();
    return returnInfo; 
  } // getSlipLineTypeName

  /**
   * �P�ʂh�c�擾
   * @param  slipLineUom  �P�ʖ���
   * @return returnInfo   �P�ʂh�c   
   */
  // ver 11.5.10.2.6 Chg Start
  //public ArrayList getUomID(String slipLineUom, Date invoiceDate)
  public ArrayList getUomID(String slipLineUom)
  // ver 11.5.10.2.6 Chg End
  {
    String    uomName    = null;
    ArrayList returnInfo = new ArrayList();

    Xx03GetUomCodeVOImpl    vo  = getXx03GetUomCodeVO1();
    Xx03GetUomCodeVORowImpl row = null;

    // ver 11.5.10.2.6 Chg Start
    //vo.initQuery(slipLineUom, invoiceDate);
    vo.initQuery(slipLineUom);
    // ver 11.5.10.2.6 Chg End
    RowSetIterator selectIter = vo.createRowSetIterator("selectIter");

    int rowCount = vo.getRowCount();
    if (rowCount == 1)
    {
      selectIter.setRangeStart(0);
      selectIter.setRangeSize(rowCount);

      row = (Xx03GetUomCodeVORowImpl)selectIter.getRowAtRangeIndex(0);
      
      if (row != null)
      {
        uomName = row.getName();
      }
      returnInfo.add(uomName);
    }
    selectIter.closeRowSetIterator();
    return returnInfo; 
  } // getUomID
  //ver11.5.10.1.6 Add End

  //Ver11.5.10.1.6E 2005/12/26 Add Start
  public ArrayList getSlipLineTaxName(String slipLineTaxName, String slipLineTaxCode, Date invoiceDate)
  {
    String    taxName    = null;
    ArrayList returnInfo = new ArrayList();

    Xx03GetTaxColVOImpl    vo  = getXx03GetTaxColVO1();
    Xx03GetTaxColVORowImpl row = null;

    vo.initQuery(slipLineTaxCode, invoiceDate);
    RowSetIterator selectIter = vo.createRowSetIterator("selectIter");

    int rowCount = vo.getRowCount();
    if (rowCount == 1)
    {
      selectIter.setRangeStart(0);
      selectIter.setRangeSize(rowCount);

      row = (Xx03GetTaxColVORowImpl)selectIter.getRowAtRangeIndex(0);
      
      if (row != null)
      {
        String taxCol = row.getTaxCol();
        if (slipLineTaxName.equals(taxCol))
        {
          taxName = taxCol;
          returnInfo.add(taxName);
          //Ver11.5.10.1.6P Add Start
          returnInfo.add(row.getTaxId());
          //Ver11.5.10.1.6P Add End
          //Ver11.5.10.1.6R Add Start
          returnInfo.add(row.getAmountIncludesTaxFlag());
          //Ver11.5.10.1.6R Add End
        }
      }
    }
    selectIter.closeRowSetIterator();
    return returnInfo; 
  }
  //Ver11.5.10.1.6E 2005/12/26 Add End

  //ver11.5.10.1.6 Add Start
  /**
   * �m�F�ł�Validation�`�F�b�N
   * @param �Ȃ�
   * @return 
   */
  public Vector checkConfValidation()
  {
    // ����������
    String methodName = "checkConfValidation";
    startProcedure(getClass().getName(), methodName);

    Vector msg = new Vector();

    RowSetIterator selectHeaderIter = null;
    RowSetIterator selectLineIter = null;

    int getHeaderRowCount;
    int getLineRowCount;

    //ver 11.5.10.1.6I Add Start
    RowSetIterator selectUpdIter = null;    
    int getUpdRowCount;
    //ver 11.5.10.1.6I Add End

    try
    {
      // �r���[�E�I�u�W�F�N�g�̎擾
      OAViewObject headerVo = getXx03ConfirmDispSlipsVO1();
      OAViewObject lineVo   = getXx03ConfirmDispSlipsLineVO1();

      Xx03ConfirmDispSlipsVORowImpl     headerRow = null;
      Xx03ConfirmDispSlipsLineVORowImpl lineRow   = null;

      getHeaderRowCount = headerVo.getRowCount();
      getLineRowCount   = lineVo.getRowCount();

      selectHeaderIter  = headerVo.createRowSetIterator("selectHeaderIter");
      selectLineIter    = lineVo.createRowSetIterator("selectLineIter");

      //ver 11.5.10.1.6I Add Start
      OAViewObject updVo  = getXx03ConfirmUpdSlipsVO1();
      Xx03ConfirmUpdSlipsVORowImpl updRow  = null;
      getUpdRowCount  = updVo.getRowCount();
      selectUpdIter  = updVo.createRowSetIterator("selectUpdIter");
      //ver 11.5.10.1.6I Add End

      //ver 11.5.10.1.6I Chg Start
      //if (getHeaderRowCount > 0)
      if ((getHeaderRowCount > 0) && (getUpdRowCount > 0))
      //ver 11.5.10.1.6I Chg End
      {
        selectHeaderIter.setRangeStart(0);
        selectHeaderIter.setRangeSize(getHeaderRowCount);
        headerRow = (Xx03ConfirmDispSlipsVORowImpl)selectHeaderIter.first();

        //ver 11.5.10.1.6I Add Start
        selectUpdIter.setRangeStart(0);
        selectUpdIter.setRangeSize(getUpdRowCount);
        updRow = (Xx03ConfirmUpdSlipsVORowImpl)selectUpdIter.first();
        //ver 11.5.10.1.6I Add End

        //ver 11.5.10.1.6I Chg Start
        //if (headerRow != null)
        if ((headerRow != null) && (updRow != null))
        {
        //ver 11.5.10.1.6I Chg End
          // Validation
          // �`�F�b�N�Ώ�
          //ver 11.5.10.1.6I Chg Start
          //msg = (Vector)validateHeader( msg
          //                             ,methodName
          //                             ,headerRow.getReceivableNum()       // �`�[�ԍ�
          //                             ,headerRow.getSlipType()            // �`�[��ʃR�[�h
          //                             ,headerRow.getTransTypeId()         // ����h�c
          //                             ,headerRow.getCustomerId()          // �ڋq�h�c
          //                             ,headerRow.getCustomerOfficeId()    // �ڋq���Ə��h�c
          //                             ,headerRow.getReceiptMethodId()     // �x�����@�h�c
          //                             ,headerRow.getTermsId()             // �x�������h�c
          //                             ,headerRow.getInvoiceCurrencyCode() // �ʉ݃R�[�h
          //                             ,headerRow.getInvoiceDate()         // ���������t
          //                             ,headerRow.getOrigInvoiceNum()      // �C�����`�[�ԍ�
          //                             );
          msg = (Vector)validateHeader( msg
                                       ,methodName
                                       ,headerRow.getReceivableNum()       // �`�[�ԍ�
                                       ,headerRow.getSlipType()            // �`�[��ʃR�[�h
                                       ,headerRow.getTransTypeId()         // ����h�c
                                       ,headerRow.getCustomerId()          // �ڋq�h�c
                                       ,headerRow.getCustomerOfficeId()    // �ڋq���Ə��h�c
                                       ,headerRow.getReceiptMethodId()     // �x�����@�h�c
                                       ,headerRow.getTermsId()             // �x�������h�c
                                       ,headerRow.getInvoiceCurrencyCode() // �ʉ݃R�[�h
                                       ,headerRow.getInvoiceDate()         // ���������t
                                       ,headerRow.getOrigInvoiceNum()      // �C�����`�[�ԍ�
                                       ,headerRow.getWfStatus()            // ���[�N�t���[�X�e�[�^�X
                                       ,updRow.getApproverPersonId()       // ���F�҂h�c
                                       ,headerRow.getSlipTypeApp()         // �`�[��ʃA�v��
                                       );
          //ver 11.5.10.1.6I Chg End
        } // headerRow
      } // getHeaderRocCount
      //ver 11.5.10.1.6I Chg Start
      //else
      else if (!(getHeaderRowCount > 0))
      //ver 11.5.10.1.6I Chg End
      {
        // �G���[�E���b�Z�[�W
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "getXx03ConfirmDispSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);        
      } // getHeaderRowCount
      //ver 11.5.10.1.6I Add Start
      else if (!(getUpdRowCount > 0))
      {
        // �G���[�E���b�Z�[�W
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ConfirmUpdSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);        
      } // updRowCount
      //ver 11.5.10.1.6I Add End

      if (getLineRowCount > 0)
      {
        selectLineIter.setRangeStart(0);
        selectLineIter.setRangeSize(getLineRowCount);

        for (int i=0; i<getLineRowCount; i++)
        {
          lineRow = (Xx03ConfirmDispSlipsLineVORowImpl)selectLineIter.getRowAtRangeIndex(i);

          if (lineRow != null)
          {
            // Validation

            
            //Ver11.5.10.1.6E 2005/12/26 Change Start
            //msg = (Vector)validateLine( msg
            //                           ,i
            //                           ,methodName
            //                           ,headerRow.getReceivableNum()       // �`�[�ԍ�
            //                           ,headerRow.getSlipType()            // �`�[��ʃR�[�h
            //                           ,headerRow.getInvoiceDate()         // ���������t
            //                           ,lineRow.getSlipLineType()          // �������e�h�c
            //                           ,lineRow.getSlipLineUom()           // �P��
            //                           );
            msg = (Vector)validateLine( msg
                                       ,i
                                       ,methodName
                                       ,headerRow.getReceivableNum()       // �`�[�ԍ�
                                       //ver 11.5.10.1.6Q Del Start
                                       //,headerRow.getSlipType()            // �`�[��ʃR�[�h
                                       //ver 11.5.10.1.6Q Del End
                                       ,headerRow.getInvoiceDate()         // ���������t
                                       //ver 11.5.10.1.6Q Del Start
                                       //,lineRow.getSlipLineType()          // �������e�h�c
                                       //ver 11.5.10.1.6Q Del End
                                       ,lineRow.getSlipLineUom()           // �P��
                                       ,lineRow.getTaxName()
                                       ,lineRow.getTaxCode()
                                       //Ver11.5.10.1.6P Add Start
                                       ,lineRow.getTaxId()
                                       //Ver11.5.10.1.6P Add End
                                       //Ver11.5.10.1.6R Add Start
                                       ,lineRow.getAmountIncludesTaxFlag()
                                       //Ver11.5.10.1.6R Add End
                                       );
            //Ver11.5.10.1.6E 2005/12/26 Change End
          } // lineRow != null
        } // for loop
      } // getLineRowCount > 0

      // �I������
      endProcedure(getClass().getName(), methodName);
    }
    //ver 11.5.10.1.6Q Add Start
    catch (OAException oaEx)
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();
      }
      if(selectLineIter != null)
      {
        selectLineIter.closeRowSetIterator();
      }
      if(selectUpdIter != null)
      {
        selectUpdIter.closeRowSetIterator();
      }
      throw new OAException(oaEx.getMessage());
    }
    //ver 11.5.10.1.6Q Add End
    //ver 11.5.10.1.6Q Chg Start
    //finally
    //{
    //  if(selectHeaderIter != null)
    //  {
    //    selectHeaderIter.closeRowSetIterator();
    //  }
    //  if(selectLineIter != null)
    //  {
    //    selectLineIter.closeRowSetIterator();
    //  }
    //  //Ver11.5.10.1.6N Add Start
    //  if(selectUpdIter != null)
    //  {
    //    selectUpdIter.closeRowSetIterator();
    //  }
    //  //Ver11.5.10.1.6N Add End
    //  return msg;
    //}
    selectHeaderIter.closeRowSetIterator();
    selectLineIter.closeRowSetIterator();
    selectUpdIter.closeRowSetIterator();
    return msg;
    //ver 11.5.10.1.6Q Chg End
  } // checkConfValidation()

  //ver11.5.10.1.6B Start
  /**
   * Validation�`�F�b�N
   * @param �Ȃ�
   * @return 
   */
  //ver 11.5.10.1.6Q Chg Start
  //public Vector checkAllValidation()
  public Vector checkAllValidation(Number receivableId)
  //ver 11.5.10.1.6Q Chg End
  {
    // ����������
    String methodName = "checkAllValidation";
    startProcedure(getClass().getName(), methodName);

    Vector msg = new Vector();

    RowSetIterator selectHeaderIter = null;
    RowSetIterator selectLineIter = null;

    int getHeaderRowCount;
    int getLineRowCount;

    //ver 11.5.10.1.6I Add Start
    RowSetIterator selectSlipIter = null;    
    int getSlipRowCount;
    //ver 11.5.10.1.6I Add End

    try
    {
      // �r���[�E�I�u�W�F�N�g�̎擾
      //ver 11.5.10.1.6Q Chg Start
      //OAViewObject headerVo = getXx03ReceivableSlipsVO1();
      //OAViewObject lineVo   = getXx03ReceivableSlipsLineVO1();
      Xx03ReceivableSlipsVOImpl     headerVo = getXx03ReceivableSlipsVO1();
      Xx03ReceivableSlipsLineVOImpl lineVo   = getXx03ReceivableSlipsLineVO2();
      //ver 11.5.10.1.6Q Chg End

      Xx03ReceivableSlipsVORowImpl     headerRow = null;
      Xx03ReceivableSlipsLineVORowImpl lineRow   = null;

      //ver 11.5.10.1.6Q Add Start
      headerVo.initQuery(receivableId, new Boolean(true));
      lineVo.initQuery(receivableId);
      //ver 11.5.10.1.6Q Add End

      getHeaderRowCount = headerVo.getRowCount();
      getLineRowCount   = lineVo.getRowCount();

      selectHeaderIter = headerVo.createRowSetIterator("selectHeaderIter");
      selectLineIter   = lineVo.createRowSetIterator("selectLineIter");

      //ver 11.5.10.1.6I Add Start
      //ver 11.5.10.1.6Q Del Start
      //OAViewObject slipVo  = getXx03SlipTypesLovVO1();
      //Xx03SlipTypesLovVORowImpl slipRow  = null;
      //getSlipRowCount  = slipVo.getRowCount();
      //selectSlipIter  = slipVo.createRowSetIterator("selectSlipIter");
      //ver 11.5.10.1.6Q Del End
      //ver 11.5.10.1.6I Add End

      //ver 11.5.10.1.6I Chg Start
      //if (getHeaderRowCount > 0)
      //ver 11.5.10.1.6Q Chg Start
      //if ((getHeaderRowCount > 0) && (getSlipRowCount > 0))
      if (getHeaderRowCount > 0)
      //ver 11.5.10.1.6Q Chg End
      //ver 11.5.10.1.6I Chg End
      {
        selectHeaderIter.setRangeStart(0);
        selectHeaderIter.setRangeSize(getHeaderRowCount);
        headerRow = (Xx03ReceivableSlipsVORowImpl)selectHeaderIter.first();

        //ver 11.5.10.1.6Q Add Start
        Xx03SlipTypesLovVOImpl    slipVo  = getXx03SlipTypesLovVO2();
        Xx03SlipTypesLovVORowImpl slipRow = null;
        slipVo.initQuery(headerRow.getSlipType());
        getSlipRowCount  = slipVo.getRowCount();
        selectSlipIter  = slipVo.createRowSetIterator("selectSlipIter");
        if (getSlipRowCount > 0)
        {
        //ver 11.5.10.1.6Q Add End

          //ver 11.5.10.1.6I Add Start
          selectSlipIter.setRangeStart(0);
          selectSlipIter.setRangeSize(getSlipRowCount);
          slipRow = (Xx03SlipTypesLovVORowImpl)selectSlipIter.first();
          //ver 11.5.10.1.6I Add End

          //ver 11.5.10.1.6I Chg Start
          //if (headerRow != null){
          if ((headerRow != null) && (slipRow != null))
          {
          //ver 11.5.10.1.6I Chg End
            // �`�F�b�N�Ώ�
            //ver 11.5.10.1.6I Chg Start
            //msg = (Vector)validateHeader( msg
            //                             ,methodName
            //                             ,headerRow.getReceivableNum()       // �`�[�ԍ�
            //                             ,headerRow.getSlipType()            // �`�[��ʃR�[�h
            //                             ,headerRow.getTransTypeId()         // ����h�c
            //                             ,headerRow.getCustomerId()          // �ڋq�h�c
            //                             ,headerRow.getCustomerOfficeId()    // �ڋq���Ə��h�c
            //                             ,headerRow.getReceiptMethodId()     // �x�����@�h�c
            //                             ,headerRow.getTermsId()             // �x�������h�c
            //                             ,headerRow.getInvoiceCurrencyCode() // �ʉ݃R�[�h
            //                             ,headerRow.getInvoiceDate()         // ���������t
            //                             ,headerRow.getOrigInvoiceNum()      // �C�����`�[�ԍ�
            //                             );
            msg = (Vector)validateHeader( msg
                                         ,methodName
                                         ,headerRow.getReceivableNum()       // �`�[�ԍ�
                                         ,headerRow.getSlipType()            // �`�[��ʃR�[�h
                                         ,headerRow.getTransTypeId()         // ����h�c
                                         ,headerRow.getCustomerId()          // �ڋq�h�c
                                         ,headerRow.getCustomerOfficeId()    // �ڋq���Ə��h�c
                                         ,headerRow.getReceiptMethodId()     // �x�����@�h�c
                                         ,headerRow.getTermsId()             // �x�������h�c
                                         ,headerRow.getInvoiceCurrencyCode() // �ʉ݃R�[�h
                                         ,headerRow.getInvoiceDate()         // ���������t
                                         ,headerRow.getOrigInvoiceNum()      // �C�����`�[�ԍ�
                                         ,headerRow.getWfStatus()            // ���[�N�t���[�X�e�[�^�X
                                         ,headerRow.getApproverPersonId()    // ���F�҂h�c
                                         ,slipRow.getAttribute14()           // �`�[��ʃA�v��
                                         );
            //ver 11.5.10.1.6I Chg End
          } // headerRow
        //ver 11.5.10.1.6Q Add Start
        }
        else
        {
          // �G���[�E���b�Z�[�W
          MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03SlipTypesLovVO2")};
          throw new OAException("XX03", "APP-XX03-13034", tokens);
        } // updRowCount
        //ver 11.5.10.1.6Q Add End
      } // getHeaderRocCount
      //ver 11.5.10.1.6I Chg Start
      //else
      //ver 11.5.10.1.6Q Chg Start
      //else if (!(getHeaderRowCount > 0))
      else
      //ver 11.5.10.1.6Q Chg End
      //ver 11.5.10.1.6I Chg End
      {
        // �G���[�E���b�Z�[�W
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);        
      } // getHeaderRowCount
      //ver 11.5.10.1.6I Add Start
      //ver 11.5.10.1.6Q Del Start
      //else if (!(getSlipRowCount > 0))
      //{
      //  // �G���[�E���b�Z�[�W
      //  MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03SlipTypesLovVO1")};
      //  throw new OAException("XX03", "APP-XX03-13034", tokens);        
      //} // updRowCount
      //ver 11.5.10.1.6Q Del End
      //ver 11.5.10.1.6I Add End

      if (getLineRowCount > 0)
      {
        selectLineIter.setRangeStart(0);
        selectLineIter.setRangeSize(getLineRowCount);
        for (int i=0; i<getLineRowCount; i++)
        {
          lineRow = (Xx03ReceivableSlipsLineVORowImpl)selectLineIter.getRowAtRangeIndex(i);

          if (lineRow != null)
          {
            // Validation


            //Ver11.5.10.1.6E 2005/12/26 Change Start
            //msg = (Vector)validateLine( msg
            //                           ,i
            //                           ,methodName
            //                           ,headerRow.getReceivableNum()       // �`�[�ԍ�
            //                          ,headerRow.getSlipType()            // �`�[��ʃR�[�h
            //                           ,headerRow.getInvoiceDate()         // ���������t
            //                           ,lineRow.getSlipLineType()          // �������e�h�c
            //                           ,lineRow.getSlipLineUom()           // �P��
            //                           );
            msg = (Vector)validateLine( msg
                                       ,i
                                       ,methodName
                                       ,headerRow.getReceivableNum()       // �`�[�ԍ�
                                       //ver 11.5.10.1.6Q Del Start
                                       //,headerRow.getSlipType()            // �`�[��ʃR�[�h
                                       //ver 11.5.10.1.6Q Del End
                                       ,headerRow.getInvoiceDate()         // ���������t
                                       //ver 11.5.10.1.6Q Del Start
                                       //,lineRow.getSlipLineType()          // �������e�h�c
                                       //ver 11.5.10.1.6Q Del End
                                       ,lineRow.getSlipLineUom()           // �P��
                                       ,lineRow.getTaxName()
                                       ,lineRow.getTaxCode()
                                       //Ver11.5.10.1.6P Add Start
                                       ,lineRow.getTaxId()
                                       //Ver11.5.10.1.6P Add End
                                       //Ver11.5.10.1.6R Add Start
                                       ,lineRow.getAmountIncludesTaxFlag()
                                       //Ver11.5.10.1.6R Add End
                                       );
            //Ver11.5.10.1.6E 2005/12/26 Change End
          } // lineRow != null
        } // for loop
      } // getLineRowCount > 0
      //ver 11.5.10.1.6Q Add Start
      else
      {
        // �G���[�E���b�Z�[�W
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsLineVO2")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);        
      } // getHeaderRowCount
      //ver 11.5.10.1.6Q Add Start

      // �I������
      endProcedure(getClass().getName(), methodName);
    }
    //ver 11.5.10.1.6Q Add Start
    catch (OAException oaEx)
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();
      }
      if(selectLineIter != null)
      {
        selectLineIter.closeRowSetIterator();
      }
      if(selectSlipIter != null)
      {
        selectSlipIter.closeRowSetIterator();
      }
      throw new OAException(oaEx.getMessage());
    }
    //ver 11.5.10.1.6Q Add End
    //ver 11.5.10.1.6Q Chg Start
    //finally
    //{
    //  if(selectHeaderIter != null)
    //  {
    //    selectHeaderIter.closeRowSetIterator();
    //  }
    //  if(selectLineIter != null)
    //  {
    //    selectLineIter.closeRowSetIterator();
    //  }
    //  return msg;
    //}
    selectHeaderIter.closeRowSetIterator();
    selectLineIter.closeRowSetIterator();
    selectSlipIter.closeRowSetIterator();
    return msg;
    //ver 11.5.10.1.6Q Chg End
  } // checkAllValidation()
  //ver11.5.10.1.6B End

  //ver11.5.10.1.6 Add End

  //ver11.5.10.2.3 Add Start
  /**
   * �\���ł�Validation�`�F�b�N
   * @param �Ȃ�
   * @return 
   */
  public Vector checkApplyValidation()
  {
    // ����������
    String methodName = "checkApplyValidation";
    startProcedure(getClass().getName(), methodName);


    OAException  msg     = null;                         // �G���[���b�Z�[�W
    Vector exception     = new Vector();
    Vector exceptionConf = new Vector();

    // �r���[�E�I�u�W�F�N�g�̎擾
    Xx03ConfirmDispSlipsVOImpl headerVo = getXx03ConfirmDispSlipsVO1();
    Xx03ConfirmDispSlipsVORowImpl headerRow =
          (Xx03ConfirmDispSlipsVORowImpl)headerVo.first();

    Xx03GetArMenuSlipTypeVOImpl menuVo = getXx03GetArMenuSlipTypeVO1();
    menuVo.initQuery(headerRow.getSlipType());
    Xx03GetArMenuSlipTypeVORowImpl menuRow =
          (Xx03GetArMenuSlipTypeVORowImpl)menuVo.first();
    Number mCnt = menuRow.getCnt();

    if (mCnt.intValue() == 0)
    {
      //�`�[��ʖ����G���[
      msg = new OAException( "XX03" ,"APP-XX03-14152");
      exception.addElement(msg);
    }

    exceptionConf = checkConfValidation();
    if (!exceptionConf.isEmpty())
    {
      //ver 11.5.10.2.4 Chg Start
      //exception.addElement(exceptionConf);
      exception.addAll(exceptionConf);
      //ver 11.5.10.2.4 Chg End
    }

    //ver 11.5.10.3 Add Start
    //�ڋqID�Z�L�����e�B�`�F�b�N
    exceptionConf = checkCustomerId(headerRow.getCustomerId()); // �ڋq�h�c
    if (!exceptionConf.isEmpty())
    {
      exception.addAll(exceptionConf);
    }
    //ver 11.5.10.3 Add End

    // �I������
    endProcedure(getClass().getName(), methodName);
    
    return exception;
  } // checkApplyValidation()
  //ver11.5.10.2.3 Add End

  //ver 11.5.10.1.6I Add Start
  /**
   * �f�t�H���g���F�҂��擾����B
   */
  public void getDefaultApprover ()
  {
    // �ύX�t���O 
    boolean changeFlag = false;

    Xx03ConfirmDispSlipsVOImpl    hVo  = getXx03ConfirmDispSlipsVO1();
    Xx03ConfirmDispSlipsVORowImpl hRow = null;
    hVo.first();
    hRow = (Xx03ConfirmDispSlipsVORowImpl)hVo.getCurrentRow();

    String slipTypeApp = hRow.getSlipTypeApp();

    Xx03GetDefaultApproverVOImpl    vo  = getXx03GetDefaultApproverVO1();
    Xx03GetDefaultApproverVORowImpl row = null;
    vo.initQuery(slipTypeApp);

    // �f�t�H���g�̏��F�҂����݂��Ȃ� 
    if (vo.getRowCount() == 0)
    {
      changeFlag = true;
    }
    else
    {
      vo.first();
      row = (Xx03GetDefaultApproverVORowImpl)vo.getCurrentRow();
    }

    Xx03ConfirmUpdSlipsVOImpl    uVo  = getXx03ConfirmUpdSlipsVO1();
    Xx03ConfirmUpdSlipsVORowImpl uRow = null;
    uVo.first();
    uRow = (Xx03ConfirmUpdSlipsVORowImpl)uVo.getCurrentRow();


    // VO���珳�F�҂��擾�����ꍇ 
    if (!changeFlag)
    {
      uRow.setApproverPersonId(row.getSupervisorId());
      uRow.setApproverPersonName(row.getApproverCol());
    }
    else
    {
      uRow.setApproverPersonId(null);
      uRow.setApproverPersonName("");
    }
  }
  //ver 11.5.10.1.6I Add End


  //Ver11.5.10.1.6M Add Start
  /**
   * ��s���폜����B
   */
  private void removeEmptyRows() 
  {
    OAViewObject lineVO = getXx03ReceivableSlipsLineVO1();    
    RowSetIterator it=lineVO.createRowSetIterator("iterator");

    try
    {
      Xx03ReceivableSlipsLineVORowImpl row;
      while(null!=(row=(Xx03ReceivableSlipsLineVORowImpl)it.next())) 
      {
        if(!row.isInput())
        {
          // ��s�͍폜�B
          row.remove();
        }
      }
    }
    finally
    {
      it.closeRowSetIterator();
    }
  }
  //Ver11.5.10.1.6M Add End

  /**
   * 
   * Container's getter for Xx03GetTransTypeNameVO1
   */
  public Xx03GetTransTypeNameVOImpl getXx03GetTransTypeNameVO1()
  {
    return (Xx03GetTransTypeNameVOImpl)findViewObject("Xx03GetTransTypeNameVO1");
  }

  /**
   * 
   * Container's getter for Xx03GetArCustomerNameVO1
   */
  public Xx03GetArCustomerNameVOImpl getXx03GetArCustomerNameVO1()
  {
    return (Xx03GetArCustomerNameVOImpl)findViewObject("Xx03GetArCustomerNameVO1");
  }

  /**
   * 
   * Container's getter for Xx03GetArCustSiteNameVO1
   */
  public Xx03GetArCustSiteNameVOImpl getXx03GetArCustSiteNameVO1()
  {
    return (Xx03GetArCustSiteNameVOImpl)findViewObject("Xx03GetArCustSiteNameVO1");
  }

  /**
   * 
   * Container's getter for Xx03GetReceiptMethodNameVO1
   */
  public Xx03GetReceiptMethodNameVOImpl getXx03GetReceiptMethodNameVO1()
  {
    return (Xx03GetReceiptMethodNameVOImpl)findViewObject("Xx03GetReceiptMethodNameVO1");
  }

  /**
   * 
   * Container's getter for Xx03GetTermsNameVO1
   */
  public Xx03GetTermsNameVOImpl getXx03GetTermsNameVO1()
  {
    return (Xx03GetTermsNameVOImpl)findViewObject("Xx03GetTermsNameVO1");
  }

  /**
   * 
   * Container's getter for Xx03GetArLinesNameVO1
   */
  public Xx03GetArLinesNameVOImpl getXx03GetArLinesNameVO1()
  {
    return (Xx03GetArLinesNameVOImpl)findViewObject("Xx03GetArLinesNameVO1");
  }

  /**
   * 
   * Container's getter for Xx03GetUomCodeVO1
   */
  public Xx03GetUomCodeVOImpl getXx03GetUomCodeVO1()
  {
    return (Xx03GetUomCodeVOImpl)findViewObject("Xx03GetUomCodeVO1");
  }

  /**
   * 
   * Container's getter for Xx03GetCurrencyNameVO1
   */
  public Xx03GetCurrencyNameVOImpl getXx03GetCurrencyNameVO1()
  {
    return (Xx03GetCurrencyNameVOImpl)findViewObject("Xx03GetCurrencyNameVO1");
  }

  /**
   * 
   * Container's getter for Xx03EnableSlipTypeVO1
   */
  public Xx03EnableSlipTypeVOImpl getXx03EnableSlipTypeVO1()
  {
    return (Xx03EnableSlipTypeVOImpl)findViewObject("Xx03EnableSlipTypeVO1");
  }

  /**
   * 
   * Container's getter for Xx03GetTaxColVO1
   */
  public Xx03GetTaxColVOImpl getXx03GetTaxColVO1()
  {
    return (Xx03GetTaxColVOImpl)findViewObject("Xx03GetTaxColVO1");
  }

  /**
   * 
   * Container's getter for Xx03SlipTypesLovVO1
   */
  public Xx03SlipTypesLovVOImpl getXx03SlipTypesLovVO1()
  {
    return (Xx03SlipTypesLovVOImpl)findViewObject("Xx03SlipTypesLovVO1");
  }

  /**
   * 
   * Container's getter for Xx03ReceivableSlipsToSlipNameVL1
   */
  public ViewLinkImpl getXx03ReceivableSlipsToSlipNameVL1()
  {
    return (ViewLinkImpl)findViewLink("Xx03ReceivableSlipsToSlipNameVL1");
  }

  /**
   * 
   * Container's getter for Xx03GetDefaultApproverVO1
   */
  public Xx03GetDefaultApproverVOImpl getXx03GetDefaultApproverVO1()
  {
    return (Xx03GetDefaultApproverVOImpl)findViewObject("Xx03GetDefaultApproverVO1");
  }

  /**
   * 
   * Container's getter for Xx03GetApproverNameVO1
   */
  public Xx03GetApproverNameVOImpl getXx03GetApproverNameVO1()
  {
    return (Xx03GetApproverNameVOImpl)findViewObject("Xx03GetApproverNameVO1");
  }

  /**
   * 
   * Container's getter for Xx03SlipTypesLovVO2
   */
  public Xx03SlipTypesLovVOImpl getXx03SlipTypesLovVO2()
  {
    return (Xx03SlipTypesLovVOImpl)findViewObject("Xx03SlipTypesLovVO2");
  }

  /**
   * 
   * Container's getter for Xx03ReceivableSlipsLineVO2
   */
  public Xx03ReceivableSlipsLineVOImpl getXx03ReceivableSlipsLineVO2()
  {
    return (Xx03ReceivableSlipsLineVOImpl)findViewObject("Xx03ReceivableSlipsLineVO2");
  }

  /**
   * 
   * Container's getter for Xx03GetArMenuSlipTypeVO1
   */
  public Xx03GetArMenuSlipTypeVOImpl getXx03GetArMenuSlipTypeVO1()
  {
    return (Xx03GetArMenuSlipTypeVOImpl)findViewObject("Xx03GetArMenuSlipTypeVO1");
  }

  /**
   * 
   * Container's getter for Xx03ChkUsrDepartmentVO1
   */
  public Xx03ChkUsrDepartmentVOImpl getXx03ChkUsrDepartmentVO1()
  {
    return (Xx03ChkUsrDepartmentVOImpl)findViewObject("Xx03ChkUsrDepartmentVO1");
  }

  //ver11.5.10.3 Add Start
  /**
   * 
   * Container's getter for Xx03ChkArCustomerVO1
   */
  public Xx03ChkArCustomerVOImpl Xx03ChkArCustomerVO1()
  {
    return (Xx03ChkArCustomerVOImpl)findViewObject("Xx03ChkArCustomerVO1");
  }
  //ver11.5.10.3 Add End

  //ver 11.5.10.2.6D Add Start
  /**
   *
   * ���ׂ̑��݃`�F�b�N(���݂��Ȃ��ꍇ�G���[�\��)
   */
  public void checkLineInput()
  {
    // ����������
    String methodName = "checkLineInput";
    startProcedure(getClass().getName(), methodName);

    // ���׃��R�[�h���݃t���O
    boolean blnRowImp = false;

    // ���חp�̃C�e���[�^
    RowSetIterator selectIter = null;

    // ���׃J�E���g
    int getRowCount;

    // ����VO
    Xx03ReceivableSlipsLineVORowImpl lineRow = null;

    // �r���[�E�I�u�W�F�N�g�̎擾
    Xx03ReceivableSlipsLineVOImpl lineVo = (Xx03ReceivableSlipsLineVOImpl)getXx03ReceivableSlipsLineVO1();

    // VO��背�R�[�h���擾
    getRowCount = lineVo.getRowCount();
    
    // VO�̃J�����g�͓������Ȃ��悤�ɃC�e���[�^���g�p
    selectIter = lineVo.createRowSetIterator("selectIter");

    // �C�e���[�^�J���̂���try final�g�p
    try
    {
      // �C�e���[�^�ݒ�
      selectIter.setRangeStart(0);
      selectIter.setRangeSize(getRowCount);
      
      // ���ׂ̃`�F�b�N
      for (int i=0; i<getRowCount; i++)
      {
        // VO���Row�̎擾
        lineRow = (Xx03ReceivableSlipsLineVORowImpl)selectIter.getRowAtRangeIndex(i);
        if (lineRow != null)
        {
          // ���̓`�F�b�N���\�b�h���Ăяo���ă`�F�b�N
          if (lineRow.isInput())
          {
            // �t���O��True�Ƃ����[�v�I��
            blnRowImp = true;
            i = getRowCount;
          }
        }
      }

      // ���R�[�h�����݂��Ȃ��ꍇ�G���[
      if (blnRowImp == false)
      {
        // ���ז����G���[
        throw new OAException( "XX03"
                              ,"APP-XX03-13057"
                              ,null
                              ,OAException.ERROR
                              ,null);
      }
    } // try
    catch(OAException ex)
    {
      throw OAException.wrapperException(ex);
    }
    finally
    {
      selectIter.closeRowSetIterator();
    }

    // �I������
    endProcedure(getClass().getName(), methodName);
  } // checkLineInput()
  //ver 11.5.10.2.6D Add End

  //ver 11.5.10.2.6E Add Start
  /**
   * �d�_�Ǘ����m�F
   *
   * @return �d�_�Ǘ��̏ꍇ"Y"�^�قȂ�ꍇ"N"
   */
  public String setAccAppFlag_Conf()
  {
    String retString = "";
    
    Xx03ConfirmDispSlipsVOImpl    dispVo  = getXx03ConfirmDispSlipsVO1();
    Xx03ConfirmDispSlipsVORowImpl dispRow = (Xx03ConfirmDispSlipsVORowImpl)dispVo.first();
    Xx03ConfirmUpdSlipsVOImpl     updVo   = getXx03ConfirmUpdSlipsVO1();
    Xx03ConfirmUpdSlipsVORowImpl  updRow  = (Xx03ConfirmUpdSlipsVORowImpl)updVo.first();

    if (!Xx03CommonUtil.STATUS_SAVE.equals(dispRow.getWfStatus()))
    {
      return updRow.getAccountApprovalFlag();
    }

    OADBTransaction txn = (OADBTransaction)getTransaction();

    // ���sSQL�u���b�N
    CallableStatement state = txn.createCallableStatement(
      "begin XX03_DEPTINPUT_AR_CHECK_PKG.SET_ACCOUNT_APPROVAL_FLAG" +
      "(:1, :2, :3, :4, :5); end;", 0);

    try
    {
      Long l = new Long(dispRow.getReceivableId().longValue());
      long recIdLong = l.longValue();
      state.setLong(1, recIdLong);
      state.registerOutParameter(2, Types.VARCHAR);
      state.registerOutParameter(3, Types.VARCHAR);
      state.registerOutParameter(4, Types.VARCHAR);
      state.registerOutParameter(5, Types.VARCHAR);

      state.execute();
      String retFlag = state.getString(2);
      String retCode = state.getString(4);
      String retMesg = state.getString(5);
      state.close();

      // �G���[�͂Ȃ�
      if (retCode.equals("0"))
      {
        // �d�_�Ǘ��t���O�̃Z�b�g
        updRow.setAccountApprovalFlag(retFlag);
        getTransaction().commit();
        return retFlag;
      }
      return retString;
    }
    catch (SQLException sqlex)
    {
      throw new OAException(sqlex.getMessage());
    }
    finally
    {
      try
      {
        state.close();
      }
      catch (SQLException ex)
      {
        throw OAException.wrapperException(ex);
      }
    }
  }

  /**
   * 
   * Container's getter for XX03GetItemFormatVO1
   */
  public XX03GetItemFormatVOImpl getXX03GetItemFormatVO1()
  {
    return (XX03GetItemFormatVOImpl)findViewObject("XX03GetItemFormatVO1");
  }

  /**
   * 
   * Container's getter for Xx03ChkArCustomerVO1
   */
  public Xx03ChkArCustomerVOImpl getXx03ChkArCustomerVO1()
  {
    return (Xx03ChkArCustomerVOImpl)findViewObject("Xx03ChkArCustomerVO1");
  }

  //ver 11.5.10.2.6E Add End

}