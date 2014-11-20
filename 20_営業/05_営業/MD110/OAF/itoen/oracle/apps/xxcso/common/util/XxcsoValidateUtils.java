/*============================================================================
* �t�@�C���� : XxcsoValidateUtils
* �T�v����   : �y�A�h�I���F�c�ƁE�c�Ɨ̈�z���ʌ��؊֐��N���X
* �o�[�W���� : 1.2
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-11 1.0  SCS����_    �V�K�쐬
* 2009-06-15 1.1  SCS�������l  [ST��QT1_1068]�֑������`�F�b�N���X�g�폜
* 2009-09-25 1.2  SCS�������  [I_E_534,I_E_548]�d�b�ԍ��̃n�C�t���Ή�
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.util;

import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.OAException;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import com.sun.java.util.collections.List;
import com.sun.java.util.collections.ArrayList;

/*******************************************************************************
 * �A�h�I���F���ʌ��؊֐��N���X
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoValidateUtils 
{
  private List   illegalStringList   = new ArrayList();
  private String enableNumberString  = "01234567890,.";
  private static XxcsoValidateUtils _instance = null;

  /*****************************************************************************
   * �K�{�`�F�b�N
   * @param errorList           �G���[���X�g
   * @param object              �`�F�b�N�Ώې���
   * @param columnName          ���ږ�
   * @param columnIndex         �s�ԍ�
   * @return List               �ǉ����ꂽ�G���[���X�g
   *****************************************************************************
   */
  public List requiredCheck(
    List    errorList
   ,Object  object
   ,String  columnName
   ,int     columnIndex
  )
  {
    if ( object == null )
    {
      OAException error = null;
      
      if ( columnIndex == 0 )
      {
        error = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00005
                 ,XxcsoConstants.TOKEN_COLUMN
                 ,columnName
                );
      }
      else
      {
        error = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00403
                 ,XxcsoConstants.TOKEN_COLUMN
                 ,columnName
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(columnIndex)
                );
      }

      errorList.add(error);
    }
    else
    {
      if ( object instanceof String )
      {
        if ( "".equals(((String)object).trim()) )
        {
          OAException error = null;
          
          if ( columnIndex == 0 )
          {
             error = XxcsoMessage.createErrorMessage(
                       XxcsoConstants.APP_XXCSO1_00005
                      ,XxcsoConstants.TOKEN_COLUMN
                      ,columnName
                     );
          }
          else
          {
            error = XxcsoMessage.createErrorMessage(
                      XxcsoConstants.APP_XXCSO1_00403
                     ,XxcsoConstants.TOKEN_COLUMN
                     ,columnName
                     ,XxcsoConstants.TOKEN_INDEX
                     ,String.valueOf(columnIndex)
                    );
          }
          errorList.add(error);
        }
      }
    }
    return errorList;
  }

  /*****************************************************************************
   * ���͂��ꂽ�������w��̏����ɂ����Ă��邩���m�F����
   * @param errorList           �G���[���X�g
   * @param checkString         �`�F�b�N�Ώە���
   * @param columnName          ���ږ�
   * @param columnIndex         �s�ԍ�
   * @return List               �ǉ����ꂽ�G���[���X�g
   *****************************************************************************
   */
  public List checkIllegalString(
    List   errorList
   ,String checkString
   ,String columnName
   ,int    columnIndex
  )
  {
    if ( checkString == null || "".equals(checkString.trim()) )
    {
      return errorList;
    }
    
    StringBuffer tokenStrings = new StringBuffer(100);
    
    for ( int i = 0; i < illegalStringList.size(); i++ )
    {
      String illegalString = (String)illegalStringList.get(i);
      int index = checkString.indexOf(illegalString);
      if ( index < 0 )
      {
        continue;
      }
      tokenStrings.append(illegalString);
    }

    if ( tokenStrings.length() > 0 )
    {
      OAException error = null;
      
      if ( columnIndex == 0 )
      {
        error = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00320
                 ,XxcsoConstants.TOKEN_COLUMN
                 ,columnName
                 ,XxcsoConstants.TOKEN_STRINGS
                 ,tokenStrings.toString()
                );
      }
      else
      {
        error = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00404
                 ,XxcsoConstants.TOKEN_COLUMN
                 ,columnName
                 ,XxcsoConstants.TOKEN_STRINGS
                 ,tokenStrings.toString()
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(columnIndex)
                );
      }
      errorList.add(error);
    }

    return errorList;
  }

  /*****************************************************************************
   * ���͂��ꂽ�������w��̏����ɂ����Ă��邩���m�F����
   * 1. �K�{�`�F�b�N�L���H                    NG�̏ꍇ�A�����ɃG���[
   * 2. ������[,][.]�������H                  NG�̏ꍇ�A�����ɃG���[
   * 3. [.]�̐����ő�1���H                  NG�̏ꍇ�A�����ɃG���[
   * 4. [,]���ςȂƂ���ɓ����Ă��Ȃ����H     NG�̏ꍇ�A�����ɃG���[
   * 5. �����_�̌����`�F�b�N                  NG�̏ꍇ�A�G���[���X�^�b�N
   * 6. �����̍ő包���`�F�b�N                NG�̏ꍇ�A�G���[���X�^�b�N
   * 7. 0�l�`�F�b�N                           NG�̏ꍇ�A�G���[���X�^�b�N
   * 8. �����[.][,]���`�F�b�N                NG�̏ꍇ�A�G���[���X�^�b�N
   * @param errorList           �G���[���X�g
   * @param stringNumber        �`�F�b�N�Ώې���
   * @param columnName          ���ږ�
   * @param floatDigit          �����_�ȉ��̍ő包��
   * @param maxDigit            �����̍ő包��
   * @param minusCheckFlag      �}�C�i�X�`�F�b�N�L��  true  : �`�F�b�N�L
   *                                                  false : �`�F�b�N��
   * @param zeroCheckFlag       0�l�`�F�b�N�L��       true  : �`�F�b�N�L
   *                                                  false : �`�F�b�N��
   * @param requiredCheckFlag   �K�{�`�F�b�N�L��      true  : �`�F�b�N�L
   *                                                  false : �`�F�b�N��
   * @param columnIndex         �s�ԍ�
   * @return List               �ǉ����ꂽ�G���[���X�g
   *****************************************************************************
   */
  public List checkStringToNumber(
    List    errorList
   ,String  stringNumber
   ,String  columnName
   ,int     floatDigit
   ,int     maxDigit
   ,boolean minusCheckFlag
   ,boolean zeroCheckFlag
   ,boolean requiredCheckFlag
   ,int     columnIndex
  )
  {
    //�K�{�`�F�b�N
    if ( requiredCheckFlag )
    {
      if ( stringNumber == null || "".equals(stringNumber.trim()) )
      {
        OAException error = null;
        
        if ( columnIndex == 0 )
        {
          error = XxcsoMessage.createErrorMessage(
                    XxcsoConstants.APP_XXCSO1_00005
                   ,XxcsoConstants.TOKEN_COLUMN
                   ,columnName
                  );
        }
        else
        {
          error = XxcsoMessage.createErrorMessage(
                    XxcsoConstants.APP_XXCSO1_00403
                   ,XxcsoConstants.TOKEN_COLUMN
                   ,columnName
                   ,XxcsoConstants.TOKEN_INDEX
                   ,String.valueOf(columnIndex)
                  );
        }
        
        errorList.add(error);
        return errorList;
      }
    }
    else
    {
      if ( stringNumber == null || "".equals(stringNumber.trim()) )
      {
        return errorList;
      }
    }
    
    // ���l�ɕϊ��ł��Ȃ��������܂܂�Ă��Ȃ����m�F����
    for ( int i = 0; i < stringNumber.length(); i++ )
    {
      char checkChar = stringNumber.charAt(i);
      //�擪��[-]�̓G���[�ɂ��Ȃ�
      if ( i == 0)
      {
        if ( checkChar == '-' )
        {
          continue;
        }
      }

      int index = enableNumberString.indexOf(checkChar);
      if ( index < 0 )
      {
        OAException error = null;
        
        if ( columnIndex == 0 )
        {
          error = XxcsoMessage.createErrorMessage(
                    XxcsoConstants.APP_XXCSO1_00009
                   ,XxcsoConstants.TOKEN_COLUMN
                   ,columnName
                  );
        }
        else
        {
          error = XxcsoMessage.createErrorMessage(
                    XxcsoConstants.APP_XXCSO1_00405
                   ,XxcsoConstants.TOKEN_COLUMN
                   ,columnName
                   ,XxcsoConstants.TOKEN_INDEX
                   ,String.valueOf(columnIndex)
                  );
        }
        
        errorList.add(error);
        return errorList;
      }
    }

    //�����[.][,]���`�F�b�N
    String dotBackString = ".";
    String commaBackString = ",";

    if ( stringNumber.endsWith(dotBackString) ||
         stringNumber.endsWith(commaBackString) )
    {
      OAException error = null;
      
      if ( columnIndex == 0 )
      {
        error = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00009
                 ,XxcsoConstants.TOKEN_COLUMN
                 ,columnName
                );
      }
      else
      {
        error = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00405
                 ,XxcsoConstants.TOKEN_COLUMN
                 ,columnName
                   ,XxcsoConstants.TOKEN_INDEX
                   ,String.valueOf(columnIndex)
                );
      }
      
      errorList.add(error);
      return errorList;      
    }
    //�擪��[.]�̏ꍇ�A"0"��t������
    String convString = stringNumber;
    if ( stringNumber.indexOf(".") == 0 )
    {
      convString = "0".concat(convString);
    }
    // [.]�ŕ�������
    String[] dotSplitString = convString.split("\\.");
    if ( dotSplitString.length > 2 )
    {
      OAException error = null;
      
      if ( columnIndex == 0 )
      {
        error = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00009
                 ,XxcsoConstants.TOKEN_COLUMN
                 ,columnName
                );
      }
      else
      {
        error = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00405
                 ,XxcsoConstants.TOKEN_COLUMN
                 ,columnName
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(columnIndex)
                );
      }
      
      errorList.add(error);
      return errorList;      
    }

    //[,]�ŕ�������
    String[] commaSplitString = dotSplitString[0].split(",");

    //[,]���P�ȏ゠��ꍇ�`�F�b�N���s��
    if ( commaSplitString.length > 1 )
    {
      for (int i = 0 ; i < commaSplitString.length ; i++)
      {
        //1����
        if ( i == 0 )
        {
          //�J���}�Ŏn�܂镶���̓G���[
          if ( commaSplitString[i].length() == 0  )
          {
            OAException error = null;
            
            if ( columnIndex == 0 )
            {
              error = XxcsoMessage.createErrorMessage(
                        XxcsoConstants.APP_XXCSO1_00009
                       ,XxcsoConstants.TOKEN_COLUMN
                       ,columnName
                      );
            }
            else
            {
              error = XxcsoMessage.createErrorMessage(
                        XxcsoConstants.APP_XXCSO1_00405
                       ,XxcsoConstants.TOKEN_COLUMN
                       ,columnName
                       ,XxcsoConstants.TOKEN_INDEX
                       ,String.valueOf(columnIndex)
                      );
            }
            
            errorList.add(error);
            return errorList;
          }
        }
        //2���ڈȍ~
        else
        {
          //�R�̔{���ȊO�̏ꍇ�̓G���[
          int dividing = commaSplitString[i].length() % 3;

          if ( dividing != 0 ||commaSplitString[i].length() == 0 )
          {
            OAException error = null;
            
            if ( columnIndex == 0 )
            {
              error = XxcsoMessage.createErrorMessage(
                        XxcsoConstants.APP_XXCSO1_00009
                       ,XxcsoConstants.TOKEN_COLUMN
                       ,columnName
                      );
            }
            else
            {
              error = XxcsoMessage.createErrorMessage(
                        XxcsoConstants.APP_XXCSO1_00405
                       ,XxcsoConstants.TOKEN_COLUMN
                       ,columnName
                       ,XxcsoConstants.TOKEN_INDEX
                       ,String.valueOf(columnIndex)
                      );
            }
            
            errorList.add(error);
            return errorList;
          }
        }
      }
    }

    //�����̌����`�F�b�N
    String integerString = dotSplitString[0];
    String floatString   = null;
    if ( dotSplitString.length == 2 )
    {
      floatString = dotSplitString[1];

      if ( floatDigit < floatString.length() )
      {
        OAException error = null;
        
        if ( floatDigit == 0 )
        {
          if ( zeroCheckFlag )
          {
            if ( columnIndex == 0 )
            {
              error = XxcsoMessage.createErrorMessage(
                        XxcsoConstants.APP_XXCSO1_00314
                       ,XxcsoConstants.TOKEN_ENTRY
                       ,columnName
                      );
            }
            else
            {
              error = XxcsoMessage.createErrorMessage(
                        XxcsoConstants.APP_XXCSO1_00408
                       ,XxcsoConstants.TOKEN_ENTRY
                       ,columnName
                       ,XxcsoConstants.TOKEN_INDEX
                       ,String.valueOf(columnIndex)
                      );
            }
          }
          else
          {
            if ( minusCheckFlag )
            {
              if ( columnIndex == 0 )
              {
                error = XxcsoMessage.createErrorMessage(
                          XxcsoConstants.APP_XXCSO1_00315
                         ,XxcsoConstants.TOKEN_ENTRY
                         ,columnName
                        );
              }
              else
              {
                error = XxcsoMessage.createErrorMessage(
                          XxcsoConstants.APP_XXCSO1_00409
                         ,XxcsoConstants.TOKEN_ENTRY
                         ,columnName
                         ,XxcsoConstants.TOKEN_INDEX
                         ,String.valueOf(columnIndex)
                        );
              }
            }
            else
            {
              if ( columnIndex == 0 )
              {
                error = XxcsoMessage.createErrorMessage(
                          XxcsoConstants.APP_XXCSO1_00528
                         ,XxcsoConstants.TOKEN_ENTRY
                         ,columnName
                        );
              }
              else
              {
                error = XxcsoMessage.createErrorMessage(
                          XxcsoConstants.APP_XXCSO1_00529
                         ,XxcsoConstants.TOKEN_ENTRY
                         ,columnName
                         ,XxcsoConstants.TOKEN_INDEX
                         ,String.valueOf(columnIndex)
                        );
              }
            }
          }
        }
        else
        {
          if ( columnIndex == 0 )
          {
            error = XxcsoMessage.createErrorMessage(
                      XxcsoConstants.APP_XXCSO1_00249
                     ,XxcsoConstants.TOKEN_COLUMN
                     ,columnName
                     ,XxcsoConstants.TOKEN_DIGIT
                     ,String.valueOf(floatDigit)
                    );
          }
          else
          {
            error = XxcsoMessage.createErrorMessage(
                      XxcsoConstants.APP_XXCSO1_00406
                     ,XxcsoConstants.TOKEN_COLUMN
                     ,columnName
                     ,XxcsoConstants.TOKEN_DIGIT
                     ,String.valueOf(floatDigit)
                     ,XxcsoConstants.TOKEN_INDEX
                     ,String.valueOf(columnIndex)
                    );
          }
        }
        errorList.add(error);
      }
    }

    //�����̍ő包���`�F�b�N
    String word1 = ",";
    String word2 = "";
    String integerStringRep = integerString.replaceAll(word1, word2);
    long longStringRep = Long.parseLong(integerStringRep);
    long maxValue = (long)Math.pow(10, maxDigit);

    if ( ! minusCheckFlag )
    {
      if ( (longStringRep + maxValue) <= 0 )
      {
        OAException error = null;
        if ( columnIndex == 0 )
        {
          error = XxcsoMessage.createErrorMessage(
                    XxcsoConstants.APP_XXCSO1_00487
                   ,XxcsoConstants.TOKEN_COLUMN
                   ,columnName
                   ,XxcsoConstants.TOKEN_MIN_VALUE
                   ,String.valueOf((0 - maxValue))
                  );
        }
        else
        {
          error = XxcsoMessage.createErrorMessage(
                    XxcsoConstants.APP_XXCSO1_00488
                   ,XxcsoConstants.TOKEN_COLUMN
                   ,columnName
                   ,XxcsoConstants.TOKEN_MIN_VALUE
                   ,String.valueOf((0 - maxValue))
                   ,XxcsoConstants.TOKEN_INDEX
                   ,String.valueOf(columnIndex)
                  );
        }
        
        errorList.add(error);
      }
    }

    if ( maxValue <= longStringRep )
    {
      OAException error = null;
      
      if ( columnIndex == 0 )
      {
        error = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00248
                 ,XxcsoConstants.TOKEN_COLUMN
                 ,columnName
                 ,XxcsoConstants.TOKEN_MAX_VALUE
                 ,String.valueOf(maxValue)
                );
      }
      else
      {
        error = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00407
                 ,XxcsoConstants.TOKEN_COLUMN
                 ,columnName
                 ,XxcsoConstants.TOKEN_MAX_VALUE
                 ,String.valueOf(maxValue)
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(columnIndex)
                );
      }
      
      errorList.add(error);
    }

    double doubleStringRep
      = Double.parseDouble(stringNumber.replaceAll(word1, word2));

    // 0�l�`�F�b�N
    if ( zeroCheckFlag && doubleStringRep == (double)0 )
    {
      OAException error = null;
      
      if ( columnIndex == 0 )
      {
        error = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00314
                 ,XxcsoConstants.TOKEN_ENTRY
                 ,columnName
                );
      }
      else
      {
        error = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00408
                 ,XxcsoConstants.TOKEN_ENTRY
                 ,columnName
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(columnIndex)
                );
      }
      errorList.add(error);
    }

    // �}�C�i�X�l�`�F�b�N
    if ( minusCheckFlag && doubleStringRep < (double)0 )
    {
      OAException error = null;
      
      if ( columnIndex == 0 )
      {
        error = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00126
                 ,XxcsoConstants.TOKEN_COLUMN
                 ,columnName
                );
      }
      else
      {
        error = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00410
                 ,XxcsoConstants.TOKEN_COLUMN
                 ,columnName
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(columnIndex)
                );
      }
      
      errorList.add(error);
    }
    
    return errorList;
  }

  /*****************************************************************************
   * ���͂��ꂽ�������d�b�ԍ��Ƃ��Đ����������m�F����
   * @param telNumber           �`�F�b�N�Ώە���
   * @return boolean            ����
   *****************************************************************************
   */
  public boolean isTelNumber(
    String   telNumber
  )
  {
    String enableTelString = "1234567890-";
    int sepCount = 0;
    boolean sepFlag = false;

    if ( telNumber == null || "".equals(telNumber.trim()) )
    {
      // NULL�̏ꍇ�́A����I��
      return true;
    }
    
    for ( int i = 0; i < telNumber.length(); i++ )
    {
      char checkChar = telNumber.charAt(i);

// 2009-09-25 [I_E_534,I_E_548] Add Start
//      if ( ((i == 0) || i == (telNumber.length() - 1)) && (checkChar == '-') )
//      {
//        // �擪�������͍Ōオ�u-�v�̏ꍇ��NG
//        return false;
//      }
// 2009-09-25 [I_E_534,I_E_548] Add End

      if ( enableTelString.indexOf(checkChar) < 0 )
      {
        // �d�b�ԍ��Ƃ��ĉ\�ȕ����łȂ��ꍇNG
        return false;
      }

// 2009-09-25 [I_E_534,I_E_548] Add Start
//      if ( checkChar == '-' )
//      {
//        sepCount++;
//        if ( sepFlag )
//        {
//          // �u-�v�������Ă����ꍇNG
//          return false;
//        }
//        sepFlag = true;
//      }
//      else
//      {
//        sepFlag = false;
//      }
    }

//    if ( sepCount != 2 )
//    {
//      // �u-�v��2�Ȃ��ꍇNG
//      return false;
//    }
// 2009-09-25 [I_E_534,I_E_548] Add End

    // �S�`�F�b�N��ʂ����琳��I��
    return true;
  }

  
  /*****************************************************************************
   * �C���X�^���X�擾
   * @param txn OADBTransaction�C���X�^���X
   *****************************************************************************
   */
  public static synchronized XxcsoValidateUtils getInstance(
    OADBTransaction txn
  )
  {
    if ( _instance == null )
    {
      _instance = new XxcsoValidateUtils(txn);
    }
    return _instance;
  }

  /*****************************************************************************
   * �R���X�g���N�^
   * @param txn OADBTransaction�C���X�^���X
   *****************************************************************************
   */
  private XxcsoValidateUtils(
    OADBTransaction txn
  )
  {
// 2009-06-15 [ST��QT1_1068] Del Start
//    illegalStringList.add("~");
//    illegalStringList.add("\\");
//    illegalStringList.add("�P");
//    illegalStringList.add("�\");
//    illegalStringList.add("�_");
// 2009-06-15 [ST��QT1_1068] Del End
    illegalStringList.add("�`");
// 2009-06-15 [ST��QT1_1068] Del Start
//    illegalStringList.add("�a");
//    illegalStringList.add("�c");
//    illegalStringList.add("�|");
//    illegalStringList.add("��");
//    illegalStringList.add("��");
//    illegalStringList.add("��");
//    illegalStringList.add("��");
// 2009-06-15 [ST��QT1_1068] Del End
  }

  /*****************************************************************************
   * �f�t�H���g�R���X�g���N�^
   *****************************************************************************
   */
  private XxcsoValidateUtils()
  {
  }
}